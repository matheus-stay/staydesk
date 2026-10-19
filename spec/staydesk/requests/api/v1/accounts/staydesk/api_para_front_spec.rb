require 'rails_helper'

# O que um front novo precisa pela API, sem recalcular regra no navegador.
RSpec.describe 'StayDesk API for a new front', type: :request do
  let(:account) { create(:account, locale: 'pt_BR') }
  let(:agent) { create(:user, account: account, role: :administrator) }
  let(:account_user) { account.account_users.find_by(user: agent) }
  let(:email) { create(:inbox, account: account, channel: create(:channel_email, account: account)) }
  let(:headers) { agent.create_new_auth_token }
  let!(:resolvido) { Staydesk::TicketStatus.create!(account: account, name: 'Resolvido', base_status: 'resolved') }

  before do
    create(:inbox_member, inbox: email, user: agent)
    create(:custom_attribute_definition, account: account, attribute_model: 'conversation_attribute', attribute_key: 'servidor',
                                         attribute_display_name: 'Servidor', attribute_display_type: 'list',
                                         attribute_values: %w[tito], staydesk_required_to_resolve: true)
  end

  def ticket
    @ticket ||= create(:conversation, account: account, inbox: email, additional_attributes: { 'mail_subject' => 'Site fora do ar' })
  end

  it 'sends the staydesk block with the conversation: subject, ticket status and what is missing' do
    get "/api/v1/accounts/#{account.id}/conversations/#{ticket.display_id}", headers: headers, as: :json

    expect(response.parsed_body['staydesk']).to include('subject' => 'Site fora do ar', 'missing_to_resolve' => ['servidor'])
    expect(ticket.push_event_data[:staydesk][:subject]).to eq('Site fora do ar')
  end

  it 'keeps the agent present through HTTP' do
    post "/api/v1/accounts/#{account.id}/staydesk/presence", headers: headers, as: :json

    expect(response.parsed_body).to include('online' => true)
    expect(OnlineStatusTracker.get_presence(account.id, 'User', agent.id)).to be_truthy
  end

  describe 'reply and set the status in one call' do
    def responder(dados)
      post "/api/v1/accounts/#{account.id}/staydesk/conversations/#{ticket.display_id}/reply", params: dados, headers: headers, as: :json
    end

    it 'saves nothing and says what is missing when a required field is empty' do
      expect { responder(content: 'Resolvido!', ticket_status_id: resolvido.id) }.not_to change(Message, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['missing_to_resolve']).to eq(['servidor'])
      expect(ticket.reload).not_to be_resolved
    end

    it 'fills the fields, replies and resolves together' do
      expect { responder(content: 'Resolvido!', ticket_status_id: resolvido.id, custom_attributes: { servidor: 'tito' }) }
        .to change(Message.outgoing, :count).by(1)

      expect(ticket.reload).to be_resolved
      expect(ticket.custom_attributes['servidor']).to eq('tito')
    end

    it 'resolves without writing anything' do
      responder(ticket_status_id: resolvido.id, custom_attributes: { servidor: 'tito' })

      expect(ticket.reload).to be_resolved
    end
  end

  it 'tells the agent in real time about offers and status changes' do
    eventos = []
    allow(ActionCable.server).to receive(:broadcast) { |_canal, dados| eventos << dados[:event] }
    disponivel = Staydesk::AgentStatus.create!(account: account, name: 'Disponível', availability: 'online')

    Staydesk::AgentStatusService.new(account_user).change_to(disponivel)
    convite = Staydesk::Offer.create!(account: account, conversation: ticket, user: agent, expires_at: 30.seconds.from_now)
    convite.update!(status: 'aceita')

    expect(eventos).to include('staydesk.agent_status.changed', 'staydesk.offer.created', 'staydesk.offer.accepted')
  end

  it 'says which Central areas the caller can configure' do
    get "/api/v1/accounts/#{account.id}/staydesk/workspace", headers: headers, as: :json

    expect(response.parsed_body['can_manage']).to include('filas' => true, 'sla' => true)
  end
end

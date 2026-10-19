require 'rails_helper'

# N1 só na fila de chat: vê os status de chat e os sem canal (almoço), não vê os
# que pegam ticket, e só recebe ticket se alguém mandar.
RSpec.describe Staydesk::AgentStatusAccess, type: :request do
  let(:account) { create(:account) }
  let(:n1) { create(:team, account: account, name: 'Suporte N1') }
  let(:n2) { create(:team, account: account, name: 'Suporte N2') }
  let(:chat) { create(:inbox, account: account) }
  let(:email) { create(:inbox, account: account, channel: create(:channel_email, account: account)) }
  let(:ana) { create(:user, account: account, role: :agent) }
  let(:vinculo) { account.account_users.find_by(user: ana) }
  let(:status) do
    {
      so_chat: Staydesk::AgentStatus.create!(account: account, name: 'Só chat', availability: 'online', work_channels: %w[chat]),
      so_tickets: Staydesk::AgentStatus.create!(account: account, name: 'Só tickets', availability: 'online', work_channels: %w[ticket]),
      disponivel: Staydesk::AgentStatus.create!(account: account, name: 'Disponível', availability: 'online', work_channels: %w[chat ticket]),
      almoco: Staydesk::AgentStatus.create!(account: account, name: 'Almoço', availability: 'busy', work_channels: [])
    }
  end

  before do
    Staydesk::LoadQueue.create!(account: account, key: 'chat', name: 'Chat', catch_all: true, position: 0)
    Staydesk::LoadQueue.create!(account: account, key: 'ticket', name: 'Tickets', channel_types: ['Channel::Email'], position: 1)
    [chat, email]
    create(:team_member, team: n1, user: ana)
    Staydesk::Queue.create!(account: account, name: 'Chat', team: n1, load_queue_keys: %w[chat], position: 0)
    Staydesk::Queue.create!(account: account, name: 'Tickets', team: n2, load_queue_keys: %w[ticket], position: 1)
  end

  it 'offers an N1 agent only the statuses of the channels its queues take' do
    liberados = described_class.new(vinculo).ids_liberados(status.values)

    expect(liberados).to contain_exactly(status[:so_chat].id, status[:almoco].id)
  end

  it 'lets an administrator pick any status' do
    vinculo.update!(role: :administrator)

    expect(described_class.new(vinculo).ids_liberados(status.values)).to match_array(status.values.map(&:id))
  end

  it 'refuses a status the agent groups do not take' do
    post "/api/v1/accounts/#{account.id}/staydesk/agent_status_periods", params: { agent_status_id: status[:so_tickets].id },
                                                                         headers: ana.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(Staydesk::AgentStatusService.new(vinculo).current).to be_nil
  end

  it 'marks in the list which statuses the agent can pick' do
    status
    get "/api/v1/accounts/#{account.id}/staydesk/agent_statuses", headers: ana.create_new_auth_token, as: :json

    liberado = response.parsed_body['statuses'].to_h { |s| [s['name'], s['available_to_me']] }
    expect(liberado).to include('Só chat' => true, 'Almoço' => true, 'Só tickets' => false, 'Disponível' => false)
  end

  it 'lets anyone send a ticket to the N1 agent, who then sees it' do
    Staydesk::QueueMembership.sync!(account)
    ticket = create(:conversation, account: account, inbox: email, status: :open)
    expect(email.reload.members).not_to include(ana)

    supervisor = create(:user, account: account, role: :administrator)
    get "/api/v1/accounts/#{account.id}/assignable_agents", params: { inbox_ids: [email.id] }, headers: supervisor.create_new_auth_token, as: :json
    expect(response.parsed_body['payload'].pluck('id')).to include(ana.id)

    ticket.update!(assignee: ana)
    expect(email.reload.members).to include(ana)

    Staydesk::QueueMembership.sync!(account)
    expect(email.reload.members).to include(ana)
  end
end

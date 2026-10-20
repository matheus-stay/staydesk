require 'rails_helper'

# No staging, a primeira resposta do agente que já punha o ticket "Em espera"
# deixava o SLA correndo: a pausa não pegava.
RSpec.describe 'SLA pauses when the first reply puts the ticket on hold', type: :request do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :administrator) }
  let(:email) { create(:inbox, account: account, channel: create(:channel_email, account: account)) }
  let!(:em_espera) { Staydesk::TicketStatus.create!(account: account, name: 'Em espera', base_status: 'pending') }

  before do
    stub_request(:any, /.*/)
    create(:inbox_member, inbox: email, user: agent)
    Staydesk::SlaPolicy.create!(account: account, name: 'SLA - Ticket', conditions: [],
                                targets: { 'default' => { 'first_response' => 150, 'resolution' => 720 } })
  end

  it 'leaves the SLA paused' do
    ticket = perform_enqueued_jobs { create(:conversation, account: account, inbox: email, assignee: agent) }
    expect(Staydesk::AppliedSla.find_by(conversation: ticket)).to be_present

    perform_enqueued_jobs do
      post "/api/v1/accounts/#{account.id}/staydesk/conversations/#{ticket.display_id}/reply",
           params: { content: 'Vou aguardar a infraestrutura', ticket_status_id: em_espera.id },
           headers: agent.create_new_auth_token, as: :json
    end

    expect(response).to have_http_status(:success)
    aplicado = Staydesk::AppliedSla.find_by(conversation: ticket)
    expect(aplicado).to have_attributes(status: 'paused')
    expect(aplicado.paused_at).to be_present
  end
end

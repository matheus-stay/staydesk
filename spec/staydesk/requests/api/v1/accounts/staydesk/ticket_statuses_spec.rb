require 'rails_helper'

RSpec.describe 'StayDesk Ticket Statuses API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: 'open') }

  before { create(:inbox_member, inbox: inbox, user: agent) }

  it 'lets an administrator manage the catalog and reorder it' do
    post "/api/v1/accounts/#{account.id}/staydesk/ticket_statuses",
         params: { ticket_status: { name: 'Novo', base_status: 'open', color: '#545DFF', default_for_base: true } },
         headers: admin.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
    novo_id = response.parsed_body['id']

    post "/api/v1/accounts/#{account.id}/staydesk/ticket_statuses",
         params: { ticket_status: { name: 'Fechado', base_status: 'resolved' } },
         headers: admin.create_new_auth_token, as: :json
    fechado_id = response.parsed_body['id']

    put "/api/v1/accounts/#{account.id}/staydesk/ticket_statuses/reorder", params: { ids: [fechado_id, novo_id] },
                                                                           headers: admin.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
    expect(response.parsed_body.pluck('name')).to eq(%w[Fechado Novo])

    get "/api/v1/accounts/#{account.id}/staydesk/ticket_statuses", headers: agent.create_new_auth_token, as: :json
    expect(response.parsed_body.pluck('name')).to eq(%w[Fechado Novo])
    expect(account.custom_attribute_definitions.find_by(attribute_key: 'staydesk_status').attribute_values).to eq(%w[Fechado Novo])
  end

  it 'forbids agents from managing the catalog' do
    post "/api/v1/accounts/#{account.id}/staydesk/ticket_statuses", params: { ticket_status: { name: 'X', base_status: 'open' } },
                                                                    headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it 'lets an agent apply a status to a conversation and returns the conversation' do
    espera = Staydesk::TicketStatus.create!(account: account, name: 'Em espera', base_status: 'pending')

    post "/api/v1/accounts/#{account.id}/staydesk/conversations/#{conversation.display_id}/ticket_status",
         params: { ticket_status_id: espera.id }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
    expect(response.parsed_body['status']).to eq('pending')
    expect(response.parsed_body['custom_attributes']['staydesk_status']).to eq('Em espera')
    expect(conversation.reload.status).to eq('pending')
  end

  it 'rejects an inactive status' do
    antigo = Staydesk::TicketStatus.create!(account: account, name: 'Antigo', base_status: 'resolved', active: false)

    post "/api/v1/accounts/#{account.id}/staydesk/conversations/#{conversation.display_id}/ticket_status",
         params: { ticket_status_id: antigo.id }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:not_found)
  end
end

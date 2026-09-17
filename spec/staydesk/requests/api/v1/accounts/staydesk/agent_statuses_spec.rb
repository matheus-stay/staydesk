require 'rails_helper'

RSpec.describe 'StayDesk Agent Statuses API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }

  it 'lets an administrator create statuses and everyone list them with the current one' do
    post "/api/v1/accounts/#{account.id}/staydesk/agent_statuses",
         params: { agent_status: { name: 'Só chat', availability: 'online', inbox_ids: [inbox.id], color: '#00ff00' } },
         headers: admin.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
    status_id = response.parsed_body['id']

    post "/api/v1/accounts/#{account.id}/staydesk/agent_status_periods", params: { agent_status_id: status_id },
                                                                          headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
    expect(response.parsed_body).to include('current_status_id' => status_id, 'availability' => 'online')

    get "/api/v1/accounts/#{account.id}/staydesk/agent_statuses", headers: agent.create_new_auth_token, as: :json
    expect(response.parsed_body['statuses'].pluck('name')).to eq(['Só chat'])
    expect(response.parsed_body['current_status_id']).to eq(status_id)
  end

  it 'forbids agents from managing the catalog and exposes periods to administrators' do
    post "/api/v1/accounts/#{account.id}/staydesk/agent_statuses", params: { agent_status: { name: 'X' } },
                                                                    headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)

    status = Staydesk::AgentStatus.create!(account: account, name: 'Ausente', availability: 'busy')
    Staydesk::AgentStatusService.new(account.account_users.find_by(user: agent)).change_to(status)

    get "/api/v1/accounts/#{account.id}/staydesk/agent_status_periods", params: { user_id: agent.id }, headers: admin.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
    expect(response.parsed_body.first).to include('user_id' => agent.id, 'agent_status_name' => 'Ausente', 'ended_at' => nil)

    get "/api/v1/accounts/#{account.id}/staydesk/agent_status_periods", headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)
  end
end

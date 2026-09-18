require 'rails_helper'

RSpec.describe 'StayDesk Capacity Rules API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  it 'creates, lists and updates a rule with its agents' do
    post "/api/v1/accounts/#{account.id}/staydesk/capacity_rules",
         params: { capacity_rule: { name: 'N1', limits: { chat: 4, ticket: 3 }, user_ids: [agent.id], is_default: true } },
         headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    id = response.parsed_body['id']
    expect(response.parsed_body).to include('limits' => { 'chat' => 4, 'ticket' => 3 }, 'user_names' => [agent.name], 'is_default' => true)

    get "/api/v1/accounts/#{account.id}/staydesk/capacity_rules", headers: agent.create_new_auth_token, as: :json
    expect(response.parsed_body.map { |r| r['name'] }).to eq(['N1'])

    patch "/api/v1/accounts/#{account.id}/staydesk/capacity_rules/#{id}",
          params: { capacity_rule: { limits: { chat: 2 } } }, headers: admin.create_new_auth_token, as: :json
    expect(response.parsed_body['limits']).to eq('chat' => 2)
  end

  it 'keeps writing for whoever configures queues' do
    post "/api/v1/accounts/#{account.id}/staydesk/capacity_rules",
         params: { capacity_rule: { name: 'N1' } }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end

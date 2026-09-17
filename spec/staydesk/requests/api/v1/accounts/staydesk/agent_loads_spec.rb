require 'rails_helper'

RSpec.describe 'StayDesk Agent Loads API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }

  it 'shows each agent with the current status, load and limit per queue' do
    status = Staydesk::AgentStatus.create!(account: account, name: 'Chat', capacity: { 'chat' => 3 })
    Staydesk::AgentStatusService.new(account.account_users.find_by(user: agent)).change_to(status)
    create(:conversation, account: account, inbox: inbox, assignee: agent, status: 'open')

    get "/api/v1/accounts/#{account.id}/staydesk/agent_loads", headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    entry = response.parsed_body.find { |row| row['user_id'] == agent.id }
    expect(entry['load']).to eq('chat' => 1, 'ticket' => 0)
    expect(entry['capacity']).to eq('chat' => 3, 'ticket' => nil)
    expect(entry['status']).to include('name' => 'Chat', 'capacity' => { 'chat' => 3 })
  end

  it 'keeps the panel for administrators' do
    get "/api/v1/accounts/#{account.id}/staydesk/agent_loads", headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end

require 'rails_helper'

RSpec.describe 'StayDesk Agent Loads API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }

  it 'shows each agent with the current status, load and limit per queue' do
    Staydesk::CapacityRule.create!(account: account, name: 'Padrão', is_default: true, limits: { 'chat' => 3 })
    status = Staydesk::AgentStatus.create!(account: account, name: 'Chat', work_channels: %w[chat])
    Staydesk::AgentStatusService.new(account.account_users.find_by(user: agent)).change_to(status)
    create(:conversation, account: account, inbox: inbox, assignee: agent, status: 'open')

    get "/api/v1/accounts/#{account.id}/staydesk/agent_loads", headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    entry = response.parsed_body.find { |row| row['user_id'] == agent.id }
    expect(entry['load']).to eq('chat' => 1, 'ticket' => 0)
    expect(entry['capacity']).to eq('chat' => 3, 'ticket' => 0)
    expect(entry['rule']).to eq('Padrão')
    expect(entry['status']).to include('name' => 'Chat', 'work_channels' => ['chat'])
  end

  it 'keeps the panel for administrators' do
    get "/api/v1/accounts/#{account.id}/staydesk/agent_loads", headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end

require 'rails_helper'

RSpec.describe 'StayDesk Workspace API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:team) { create(:team, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/staydesk/workspace' do
    it 'returns the resolved workspace for the agent' do
      Staydesk::TeamWorkspace.create!(account: account, team: team, config: { 'list' => { 'layout' => 'table' } })
      create(:team_member, team: team, user: agent)

      get "/api/v1/accounts/#{account.id}/staydesk/workspace", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to include('role' => 'agent')
      expect(response.parsed_body.dig('list', 'layout')).to eq('table')
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/staydesk/team_workspaces/{team_id}' do
    it 'is forbidden to agents' do
      put "/api/v1/accounts/#{account.id}/staydesk/team_workspaces/#{team.id}",
          params: { config: { menu: ['Conversation'] } }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates or updates the team configuration for an administrator' do
      put "/api/v1/accounts/#{account.id}/staydesk/team_workspaces/#{team.id}",
          params: { config: { menu: ['Conversation'], list: { layout: 'table' } } }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(Staydesk::TeamWorkspace.find_by(account: account, team: team).config).to include('menu' => ['Conversation'])
    end

    it 'rejects a configuration outside the schema' do
      put "/api/v1/accounts/#{account.id}/staydesk/team_workspaces/default",
          params: { config: { list: { layout: 'grid' } } }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/staydesk/team_workspaces/schema' do
    it 'returns the JSON schema' do
      get "/api/v1/accounts/#{account.id}/staydesk/team_workspaces/schema", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['properties'].keys).to include('menu', 'list', 'conversation')
    end
  end
end

require 'rails_helper'

RSpec.describe 'StayDesk Team Views API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:team) { create(:team, account: account) }
  let(:query) { { 'payload' => [{ 'attribute_key' => 'status', 'filter_operator' => 'equal_to', 'values' => ['open'], 'query_operator' => nil }] } }
  let!(:team_view) { Staydesk::TeamView.create!(account: account, name: 'Fila do time', query: query, team_ids: [team.id]) }
  let!(:hidden_view) do
    Staydesk::TeamView.create!(account: account, name: 'De outro time', query: query, team_ids: [create(:team, account: account).id])
  end

  describe 'GET /api/v1/accounts/{account.id}/staydesk/team_views' do
    it 'returns unauthorized without a user' do
      get "/api/v1/accounts/#{account.id}/staydesk/team_views"

      expect(response).to have_http_status(:unauthorized)
    end

    it 'lists only the views visible to the agent' do
      create(:team_member, team: team, user: agent)

      get "/api/v1/accounts/#{account.id}/staydesk/team_views", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.pluck('id')).to eq([team_view.id])
    end

    it 'lists every view to the administrator' do
      get "/api/v1/accounts/#{account.id}/staydesk/team_views", headers: admin.create_new_auth_token, as: :json

      expect(response.parsed_body.pluck('id')).to contain_exactly(team_view.id, hidden_view.id)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/staydesk/team_views' do
    let(:params) do
      { team_view: { name: 'Pendentes', query: query, team_ids: [team.id], columns: %w[status subject], sort_by: 'waiting_since_desc' } }
    end

    it 'is forbidden to agents' do
      post "/api/v1/accounts/#{account.id}/staydesk/team_views", params: params, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates the view for an administrator' do
      post "/api/v1/accounts/#{account.id}/staydesk/team_views", params: params, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to include('name' => 'Pendentes', 'team_ids' => [team.id], 'columns' => %w[status subject])
      expect(Staydesk::TeamView.last.created_by).to eq(admin)
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/staydesk/team_views/{id}/conversations' do
    let(:inbox) { create(:inbox, account: account) }

    before do
      create(:inbox_member, inbox: inbox, user: agent)
      create(:team_member, team: team, user: agent)
      create(:conversation, account: account, inbox: inbox, status: :open)
      create(:conversation, account: account, inbox: inbox, status: :resolved)
    end

    it 'returns the conversations matching the view query' do
      get "/api/v1/accounts/#{account.id}/staydesk/team_views/#{team_view.id}/conversations",
          headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].size).to eq(1)
      expect(response.parsed_body['meta']['all_count']).to eq(1)
    end

    it 'hides views of other teams' do
      get "/api/v1/accounts/#{account.id}/staydesk/team_views/#{hidden_view.id}/conversations",
          headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/staydesk/team_views/counts' do
    it 'returns one count per visible view' do
      create(:team_member, team: team, user: agent)

      get "/api/v1/accounts/#{account.id}/staydesk/team_views/counts", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['counts']).to eq(team_view.id.to_s => 0)
    end
  end
end

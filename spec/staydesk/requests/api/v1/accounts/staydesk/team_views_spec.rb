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

  # A lista na tela usa o filtro de conversas do produto, que não conhece o canal
  # de trabalho: ela precisa da consulta já resolvida, e o número ao lado tem de
  # bater com ela na hora, sem cache.
  describe 'work channel view' do
    let(:chat) { create(:inbox, account: account) }
    let(:email) { create(:inbox, :with_email, account: account) }
    let!(:fila_chat) do
      Staydesk::TeamView.create!(
        account: account, name: 'Fila - Chat',
        query: { 'payload' => [
          { 'attribute_key' => 'staydesk_load_queue', 'filter_operator' => 'equal_to', 'values' => ['chat'], 'query_operator' => 'and' },
          { 'attribute_key' => 'status', 'filter_operator' => 'equal_to', 'values' => ['open'], 'query_operator' => nil }
        ] }
      )
    end

    before do
      create(:conversation, account: account, inbox: chat, status: :open)
      create(:conversation, account: account, inbox: email, status: :open)
    end

    def contagem
      get "/api/v1/accounts/#{account.id}/staydesk/team_views/counts", headers: admin.create_new_auth_token, as: :json
      response.parsed_body['counts'][fila_chat.id.to_s]
    end

    it 'hands the list a query the product filter understands, matching the count' do
      get "/api/v1/accounts/#{account.id}/staydesk/team_views", headers: admin.create_new_auth_token, as: :json
      resolvida = response.parsed_body.find { |view| view['id'] == fila_chat.id }['resolved_query']

      expect(resolvida['payload'].first).to include('attribute_key' => 'inbox_id')
      expect(resolvida['payload'].first['values']).not_to include(email.id)

      post "/api/v1/accounts/#{account.id}/conversations/filter", params: { payload: resolvida['payload'] },
                                                                  headers: admin.create_new_auth_token, as: :json
      expect(response).to have_http_status(:success)
      expect(response.parsed_body.dig('meta', 'all_count')).to eq(contagem)
    end

    it 'counts a new conversation right away' do
      expect(contagem).to eq(1)

      create(:conversation, account: account, inbox: chat, status: :open)

      expect(contagem).to eq(2)
    end
  end
end

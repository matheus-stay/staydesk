require 'rails_helper'

RSpec.describe 'StayDesk API tokens', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  def cabecalho(valor)
    { api_access_token: valor }
  end

  describe 'managing the tokens' do
    it 'creates a token, shows the value once and lists it without the value' do
      post "/api/v1/accounts/#{account.id}/staydesk/api_tokens",
           params: { api_token: { name: 'Dashboard', scopes: ['relatorios:leitura'] } },
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      valor = response.parsed_body['token']
      expect(valor).to start_with('sd_')

      get "/api/v1/accounts/#{account.id}/staydesk/api_tokens", headers: admin.create_new_auth_token, as: :json
      listado = response.parsed_body['api_tokens'].first
      expect(listado['name']).to eq('Dashboard')
      expect(listado).not_to have_key('token')
      expect(response.parsed_body['scopes']).to include('relatorios:leitura', 'operacao:escrita')
    end

    it 'keeps an agent without the permission out' do
      post "/api/v1/accounts/#{account.id}/staydesk/api_tokens",
           params: { api_token: { name: 'Meu', scopes: ['relatorios:leitura'] } },
           headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'using the token' do
    let(:token) do
      Staydesk::ApiToken.gerar!(account: account, user: admin, name: 'Dashboard',
                                scopes: ['relatorios:leitura'])
    end

    it 'opens what the scope covers' do
      get "/api/v1/accounts/#{account.id}/staydesk/kpis", headers: cabecalho(token.token_em_claro), as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to have_key('csat')
    end

    it 'closes what the scope does not cover, reading or writing' do
      get "/api/v1/accounts/#{account.id}/conversations", headers: cabecalho(token.token_em_claro), as: :json
      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body['error']).to include('conversas:leitura')

      post "/api/v1/accounts/#{account.id}/staydesk/queues",
           params: { queue: { name: 'Nova', team_id: create(:team, account: account).id } },
           headers: cabecalho(token.token_em_claro), as: :json
      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body['error']).to include('operacao:escrita')
    end

    it 'records the use of the token' do
      expect do
        get "/api/v1/accounts/#{account.id}/staydesk/kpis", headers: cabecalho(token.token_em_claro), as: :json
      end.to change { token.reload.last_used_at }.from(nil)
    end

    it 'refuses a revoked token like any other invalid one' do
      valor = token.token_em_claro
      token.update!(active: false)

      get "/api/v1/accounts/#{account.id}/staydesk/kpis", headers: cabecalho(valor), as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end

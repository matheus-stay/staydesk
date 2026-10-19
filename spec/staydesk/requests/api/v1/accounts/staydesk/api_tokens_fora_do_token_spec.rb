require 'rails_helper'

# Nenhum escopo abre o perfil (que devolve o token pessoal), a criação de tokens
# nem o "entrar como": seriam a porta para um token restrito virar acesso total.
RSpec.describe 'StayDesk API tokens: paths no token reaches', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:token) do
    Staydesk::ApiToken.gerar!(account: account, user: admin, name: 'Tudo', scopes: Staydesk::ApiScope.todos)
  end
  let(:cabecalho) { { api_access_token: token.token_em_claro } }

  it 'never reads the profile, which carries the personal access token' do
    get '/api/v1/profile', headers: cabecalho, as: :json

    expect(response).to have_http_status(:forbidden)
    expect(response.body).not_to include(admin.access_token.token)
  end

  it 'never mints another token nor impersonates' do
    post "/api/v1/accounts/#{account.id}/staydesk/api_tokens", params: { api_token: { name: 'X', scopes: ['conta:escrita'] } },
                                                               headers: cabecalho, as: :json
    expect(response).to have_http_status(:forbidden)

    get "/api/v1/accounts/#{account.id}/staydesk/impersonations", headers: cabecalho, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'still opens what the scope covers' do
    get "/api/v1/accounts/#{account.id}/staydesk/kpis", headers: cabecalho, as: :json

    expect(response).to have_http_status(:success)
  end
end

require 'rails_helper'

# As rotas de autenticação não passam pela guarda do agente leve: ali ainda não
# existe sessão, e perguntar por `current_user` dentro de um controlador do
# Devise quebra o fluxo do produto. Era o 500 de quem tentava definir a senha
# pelo link de "esqueci minha senha".
RSpec.describe 'autenticação', type: :request do
  let(:account) { create(:account) }
  let!(:usuario) { create(:user, account: account, email: 'convidado@staycloud.com') }

  it 'lets the person set a new password with the reset token' do
    token = usuario.send(:set_reset_password_token)

    put '/auth/password', params: { reset_password_token: token, password: 'SenhaForte123!',
                                    password_confirmation: 'SenhaForte123!' }, as: :json

    expect(response).to have_http_status(:success)
    expect(usuario.reload.valid_password?('SenhaForte123!')).to be(true)
  end

  it 'confirms an account that never confirmed when the password is set' do
    usuario.update_columns(confirmed_at: nil) # rubocop:disable Rails/SkipsModelValidations
    token = usuario.send(:set_reset_password_token)

    put '/auth/password', params: { reset_password_token: token, password: 'SenhaForte123!',
                                    password_confirmation: 'SenhaForte123!' }, as: :json

    expect(response).to have_http_status(:success)
    expect(usuario.reload.confirmed?).to be(true)
  end

  it 'asks for the reset e-mail without blowing up' do
    post '/auth/password', params: { email: usuario.email, redirect_url: 'https://staydesk.staycloud.com.br' }, as: :json

    expect(response).to have_http_status(:success)
  end

  it 'refuses an invalid token without a server error' do
    put '/auth/password', params: { reset_password_token: 'nao-existe', password: 'SenhaForte123!',
                                    password_confirmation: 'SenhaForte123!' }, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
  end
end

require 'rails_helper'

# Superadministração por API: gerar instância nova numa chamada só.
RSpec.describe 'StayDesk instances through the Platform API', type: :request do
  let(:platform_app) { create(:platform_app) }
  let(:headers) { { api_access_token: platform_app.access_token.token } }
  let(:yaml) { "times:\n  - Suporte N1\netiquetas:\n  - { nome: vip, cor: '#545DFF' }\n" }

  def criar
    post '/platform/api/v1/staydesk/instances',
         params: { account: { name: 'Cliente X' }, admin: { name: 'Ana', email: 'ana@clientex.com' }, config_yaml: yaml },
         headers: headers, as: :json
    Account.find(response.parsed_body.dig('account', 'id'))
  end

  it 'creates the account in the StayDesk standard with its administrator' do
    conta = criar

    expect(response).to have_http_status(:created)
    expect(conta.locale).to eq('pt_BR')
    expect(conta.feature_enabled?('disable_branding')).to be(true)
    expect(conta.feature_enabled?('campaigns')).to be(false)
    expect(conta.administrators.pluck(:email)).to eq(['ana@clientex.com'])
    expect(response.parsed_body['login_url']).to be_present
  end

  it 'applies the operation file and the built-in roles' do
    conta = criar

    expect(conta.teams.pluck(:name)).to eq(['Suporte N1'])
    expect(Staydesk::Role.where(account: conta, built_in: true).count).to eq(2)
  end

  it 'lists the instances the platform app manages' do
    post '/platform/api/v1/staydesk/instances', params: { account: { name: 'Cliente Y' }, admin: { name: 'Bia', email: 'bia@y.com' } },
                                                headers: headers, as: :json
    get '/platform/api/v1/staydesk/instances', headers: headers, as: :json

    expect(response.parsed_body.pluck('name')).to include('Cliente Y')
  end

  it 'refuses without a platform token' do
    get '/platform/api/v1/staydesk/instances', as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end

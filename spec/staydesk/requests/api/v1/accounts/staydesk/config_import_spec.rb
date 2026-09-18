require 'rails_helper'

RSpec.describe 'StayDesk Config Import API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:yaml) do
    <<~YAML
      times:
        - Suporte N1
      etiquetas:
        - { nome: hospedagem, cor: '#545DFF' }
      status_do_agente:
        - { nome: Só chat, disponibilidade: online, cor: '#545DFF', recebe: [chat] }
    YAML
  end

  it 'applies a YAML configuration to the account' do
    post "/api/v1/accounts/#{account.id}/staydesk/config_import",
         params: { yaml: yaml }, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body.keys).to include('times', 'etiquetas', 'status_do_agente', 'canais')
    expect(account.teams.pluck(:name)).to eq(['suporte n1'])
    expect(account.labels.pluck(:title)).to eq(['hospedagem'])
    expect(Staydesk::AgentStatus.where(account: account).pluck(:name)).to include('Só chat')
  end

  it 'accepts the same structure as JSON and is idempotent' do
    2.times do
      post "/api/v1/accounts/#{account.id}/staydesk/config_import",
           params: { config: { times: ['Suporte N1', 'Suporte N2'] } }, headers: admin.create_new_auth_token, as: :json
      expect(response).to have_http_status(:success)
    end

    expect(account.teams.count).to eq(2)
  end

  it 'rejects invalid YAML with a readable message' do
    post "/api/v1/accounts/#{account.id}/staydesk/config_import",
         params: { yaml: "times:\n  - a\n b: [" }, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['message']).to start_with('YAML inválido')
  end

  it 'is for administrators only' do
    post "/api/v1/accounts/#{account.id}/staydesk/config_import",
         params: { yaml: yaml }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end

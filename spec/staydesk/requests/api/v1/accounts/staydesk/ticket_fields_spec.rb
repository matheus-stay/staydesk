require 'rails_helper'

RSpec.describe 'StayDesk ticket fields', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: 'open') }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    create(:custom_attribute_definition, account: account, attribute_key: 'tipo_de_demanda',
                                         attribute_display_name: 'Tipo de Demanda',
                                         attribute_model: :conversation_attribute,
                                         staydesk_required_to_resolve: true)
  end

  it 'lists the catalog with the required mark' do
    get "/api/v1/accounts/#{account.id}/staydesk/ticket_fields", headers: agent.create_new_auth_token, as: :json

    campo = response.parsed_body['ticket_fields'].first
    expect(campo['attribute_key']).to eq('tipo_de_demanda')
    expect(campo['staydesk_required_to_resolve']).to be(true)
  end

  it 'reads the fields of a conversation and what is missing' do
    get "/api/v1/accounts/#{account.id}/staydesk/conversations/#{conversation.display_id}/ticket_fields",
        headers: agent.create_new_auth_token, as: :json

    expect(response.parsed_body['missing_to_resolve']).to eq(['tipo_de_demanda'])
    expect(response.parsed_body['fields'].first).to include('key' => 'tipo_de_demanda', 'filled' => false)
  end

  it 'fills a field without touching the others' do
    conversation.update!(custom_attributes: { 'servidor' => 'srv-01' })

    patch "/api/v1/accounts/#{account.id}/staydesk/conversations/#{conversation.display_id}/ticket_fields",
          params: { custom_attributes: { tipo_de_demanda: 'Suporte' } },
          headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['missing_to_resolve']).to be_empty
    expect(conversation.reload.custom_attributes).to include('servidor' => 'srv-01', 'tipo_de_demanda' => 'Suporte')
  end

  it 'stops the agent from resolving while the field is empty, and lets it through once filled' do
    post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
         params: { status: 'resolved' }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['message']).to include('Tipo de Demanda')

    patch "/api/v1/accounts/#{account.id}/staydesk/conversations/#{conversation.display_id}/ticket_fields",
          params: { custom_attributes: { tipo_de_demanda: 'Suporte' } },
          headers: agent.create_new_auth_token, as: :json

    post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
         params: { status: 'resolved' }, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
    expect(conversation.reload.status).to eq('resolved')
  end

  it 'marks a field as required through the product endpoint' do
    definicao = account.custom_attribute_definitions.first

    patch "/api/v1/accounts/#{account.id}/custom_attribute_definitions/#{definicao.id}",
          params: { custom_attribute_definition: { staydesk_required_to_resolve: false } },
          headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['staydesk_required_to_resolve']).to be(false)
    expect(definicao.reload.staydesk_required_to_resolve).to be(false)
  end
end

require 'rails_helper'

RSpec.describe 'StayDesk SLA API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'calendars' do
    it 'creates and lists calendars for an administrator' do
      post "/api/v1/accounts/#{account.id}/staydesk/calendars",
           params: { calendar: { name: 'Comercial', timezone: 'America/Sao_Paulo', weekly_hours: [{ day: 1, open: '09:00', close: '18:00' }], holidays: [] } },
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      get "/api/v1/accounts/#{account.id}/staydesk/calendars", headers: agent.create_new_auth_token, as: :json
      expect(response.parsed_body.pluck('name')).to eq(['Comercial'])
    end

    it 'is read-only for agents' do
      post "/api/v1/accounts/#{account.id}/staydesk/calendars", params: { calendar: { name: 'X' } }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'sla policies' do
    let(:payload) do
      { sla_policy: { name: 'WhatsApp urgente', conditions: [{ attribute_key: 'inbox_id', filter_operator: 'equal_to', values: [inbox.id], query_operator: nil }],
                      targets: { default: { first_response: 30, resolution: 480 } } } }
    end

    it 'creates, reorders and lists policies' do
      post "/api/v1/accounts/#{account.id}/staydesk/sla_policies", params: payload, headers: admin.create_new_auth_token, as: :json
      expect(response).to have_http_status(:success)
      first_id = response.parsed_body['id']

      post "/api/v1/accounts/#{account.id}/staydesk/sla_policies", params: { sla_policy: { name: 'Padrão', targets: { default: { resolution: 960 } } } },
                                                                    headers: admin.create_new_auth_token, as: :json
      second_id = response.parsed_body['id']

      put "/api/v1/accounts/#{account.id}/staydesk/sla_policies/reorder", params: { ids: [second_id, first_id] }, headers: admin.create_new_auth_token, as: :json
      expect(response.parsed_body.pluck('id')).to eq([second_id, first_id])
    end

    it 'rejects targets outside the shape' do
      post "/api/v1/accounts/#{account.id}/staydesk/sla_policies", params: { sla_policy: { name: 'X', targets: { default: { nope: 1 } } } },
                                                                    headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'conversation sla and applied slas' do
    let!(:policy) { Staydesk::SlaPolicy.create!(account: account, name: 'Padrão', targets: { 'default' => { 'resolution' => 60 } }) }
    let!(:conversation) { create(:conversation, account: account, inbox: inbox) }
    let!(:applied) { Staydesk::Sla::Applier.new(conversation).perform }

    it 'returns the applied sla of a conversation by display id' do
      create(:inbox_member, inbox: inbox, user: agent)
      get "/api/v1/accounts/#{account.id}/staydesk/conversations/#{conversation.display_id}/sla", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to include('sla_policy_name' => 'Padrão', 'status' => 'running')
      expect(response.parsed_body.dig('metrics', 'resolution', 'due_at')).to be_present
    end

    it 'lists applied slas for the dashboard, administrators only' do
      get "/api/v1/accounts/#{account.id}/staydesk/applied_slas", headers: agent.create_new_auth_token, as: :json
      expect(response).to have_http_status(:unauthorized)

      get "/api/v1/accounts/#{account.id}/staydesk/applied_slas", params: { status: 'running' }, headers: admin.create_new_auth_token, as: :json
      expect(response.parsed_body.pluck('id')).to eq([applied.id])
    end
  end
end

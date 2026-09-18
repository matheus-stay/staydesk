require 'rails_helper'

RSpec.describe 'StayDesk Roles API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:account_user) { account.account_users.find_by(user: agent) }

  it 'lets an administrator create a role and hand it to an agent, then take it back' do
    post "/api/v1/accounts/#{account.id}/staydesk/roles",
         params: { role: { name: 'Supervisor', description: 'Vê relatórios', permissions: %w[report_manage] } },
         headers: admin.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
    role_id = response.parsed_body['id']

    put "/api/v1/accounts/#{account.id}/staydesk/agent_roles/#{agent.id}",
        params: { staydesk_role_id: role_id }, headers: admin.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)
    expect(response.parsed_body.first['permissions']).to include('report_manage')
    expect(account_user.reload.staydesk_can?('report_manage')).to be(true)

    put "/api/v1/accounts/#{account.id}/staydesk/agent_roles/#{agent.id}",
        params: { staydesk_role_id: nil }, headers: admin.create_new_auth_token, as: :json
    expect(response.parsed_body.first['permissions']).not_to include('report_manage')
    expect(account_user.reload.staydesk_can?('report_manage')).to be(false)
  end

  it 'refuses a permission it does not know' do
    post "/api/v1/accounts/#{account.id}/staydesk/roles",
         params: { role: { name: 'Estranho', permissions: %w[tudo] } },
         headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'keeps the role catalog with administrators' do
    post "/api/v1/accounts/#{account.id}/staydesk/roles", params: { role: { name: 'X' } },
                                                          headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it 'opens the reports for an agent whose role grants it' do
    role = Staydesk::Role.create!(account: account, name: 'Supervisor', permissions: %w[report_manage])
    Staydesk::AccountUserRole.create!(account_user: account_user, staydesk_role: role)

    get "/api/v2/accounts/#{account.id}/reports/summary", params: { type: :account, since: 1.day.ago.to_i.to_s, until: Time.current.to_i.to_s },
                                                          headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
  end

  it 'keeps an agent with own-numbers only out of someone else report' do
    outro = create(:user, account: account, role: :agent)
    role = Staydesk::Role.create!(account: account, name: 'Meus números', permissions: %w[staydesk_report_own])
    Staydesk::AccountUserRole.create!(account_user: account_user, staydesk_role: role)
    periodo = { since: 1.day.ago.to_i.to_s, until: Time.current.to_i.to_s }

    get "/api/v2/accounts/#{account.id}/reports/summary", params: periodo.merge(type: :agent, id: agent.id),
                                                          headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:success)

    get "/api/v2/accounts/#{account.id}/reports/summary", params: periodo.merge(type: :agent, id: outro.id),
                                                          headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:forbidden)

    get "/api/v2/accounts/#{account.id}/reports/summary", params: periodo.merge(type: :account),
                                                          headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:forbidden)
  end
end

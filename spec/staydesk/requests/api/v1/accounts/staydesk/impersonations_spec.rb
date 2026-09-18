require 'rails_helper'

RSpec.describe 'StayDesk Impersonations API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  it 'gives the administrator a session link for the agent and records who did it' do
    post "/api/v1/accounts/#{account.id}/staydesk/impersonations", params: { user_id: agent.id },
                                                                   headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['url']).to include('impersonation=true')
    expect(Staydesk::Impersonation.last).to have_attributes(actor_id: admin.id, target_id: agent.id, account_id: account.id)

    get "/api/v1/accounts/#{account.id}/staydesk/impersonations", headers: admin.create_new_auth_token, as: :json
    expect(response.parsed_body.first).to include('actor_name' => admin.name, 'target_name' => agent.name)
  end

  it 'is closed to agents' do
    post "/api/v1/accounts/#{account.id}/staydesk/impersonations", params: { user_id: admin.id },
                                                                   headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it 'only reaches members of the account' do
    de_fora = create(:user, account: create(:account), role: :agent)

    post "/api/v1/accounts/#{account.id}/staydesk/impersonations", params: { user_id: de_fora.id },
                                                                   headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:not_found)
  end
end

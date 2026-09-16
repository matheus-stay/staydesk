require 'rails_helper'

RSpec.describe 'StayDesk Ping API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/{account.id}/staydesk/ping' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/staydesk/ping"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns the fork and upstream versions' do
        get "/api/v1/accounts/#{account.id}/staydesk/ping",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include('staydesk' => Staydesk::VERSION, 'chatwoot' => Chatwoot.config[:version])
      end
    end
  end
end

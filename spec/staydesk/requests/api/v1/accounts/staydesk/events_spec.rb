require 'rails_helper'

RSpec.describe 'StayDesk Events API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, status: :open) }

  before do
    conversation.update!(status: :resolved)
    ReportingEvent.create!(account_id: account.id, conversation_id: conversation.id, inbox_id: inbox.id, name: 'first_response', value: 120)
  end

  it 'is forbidden to agents' do
    get "/api/v1/accounts/#{account.id}/staydesk/events", headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it 'returns both lists with the conversation display id' do
    get "/api/v1/accounts/#{account.id}/staydesk/events", headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['reporting_events'].first).to include('name' => 'first_response', 'conversation_id' => conversation.display_id)
    expect(response.parsed_body['conversation_events'].first).to include('kind' => 'status_changed', 'from' => 'open', 'to' => 'resolved')
  end

  it 'filters by conversation, kind and cursor' do
    get "/api/v1/accounts/#{account.id}/staydesk/events",
        params: { conversation_id: conversation.display_id, kind: 'status_changed', after_reporting_id: 10_000 },
        headers: admin.create_new_auth_token, as: :json

    expect(response.parsed_body['reporting_events']).to be_empty
    expect(response.parsed_body['conversation_events'].size).to eq(1)
  end
end

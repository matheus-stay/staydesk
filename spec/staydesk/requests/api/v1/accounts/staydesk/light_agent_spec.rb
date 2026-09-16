require 'rails_helper'

RSpec.describe 'StayDesk light agent', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:light) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before do
    create(:inbox_member, inbox: inbox, user: light)
    Staydesk::AccountUserRole.create!(account_user: account.account_users.find_by(user: light), kind: 'light')
  end

  it 'reads the conversation' do
    get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: light.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
  end

  it 'creates a private note' do
    post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
         params: { content: 'nota interna', private: true }, headers: light.create_new_auth_token, as: :json

    expect(response).to have_http_status(:success)
    expect(conversation.messages.last).to have_attributes(content: 'nota interna', private: true)
  end

  it 'cannot send a public message' do
    post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
         params: { content: 'resposta', private: false }, headers: light.create_new_auth_token, as: :json

    expect(response).to have_http_status(:forbidden)
  end

  it 'cannot change the status, assignee or labels' do
    headers = light.create_new_auth_token
    post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status", params: { status: 'resolved' }, headers: headers, as: :json
    expect(response).to have_http_status(:forbidden)

    post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/assignments", params: { assignee_id: light.id }, headers: headers, as: :json
    expect(response).to have_http_status(:forbidden)

    post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/labels", params: { labels: ['x'] }, headers: headers, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'is validated at the model level too' do
    message = build(:message, account: account, inbox: inbox, conversation: conversation, sender: light, message_type: :outgoing, private: false)

    expect(message).not_to be_valid
    expect(message.errors[:private]).to be_present
  end

  describe 'agent roles API' do
    it 'lets an administrator set the kind and lists it' do
      put "/api/v1/accounts/#{account.id}/staydesk/agent_roles/#{light.id}", params: { kind: 'full' }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.first).to include('user_id' => light.id, 'kind' => 'full')
    end

    it 'is forbidden to agents' do
      get "/api/v1/accounts/#{account.id}/staydesk/agent_roles", headers: light.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end

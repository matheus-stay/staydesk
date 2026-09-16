require 'rails_helper'

RSpec.describe Conversation do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :open) }

  it 'records one StayDesk event per tracked change' do
    Current.user = agent
    conversation.update!(status: :resolved, priority: :high)

    events = Staydesk::ConversationEvent.where(conversation: conversation).order(:id)
    expect(events.map(&:kind)).to contain_exactly('status_changed', 'priority_changed')
    expect(events.find_by(kind: 'status_changed')).to have_attributes(from_value: 'open', to_value: 'resolved', user_id: agent.id)
  ensure
    Current.reset
  end

  it 'records nothing when nothing tracked changed' do
    conversation.update!(custom_attributes: { 'x' => 1 })

    expect(Staydesk::ConversationEvent.where(conversation: conversation)).to be_empty
  end
end

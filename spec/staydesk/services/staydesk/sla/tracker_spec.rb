require 'rails_helper'

RSpec.describe 'StayDesk SLA lifecycle' do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let!(:policy) do
    Staydesk::SlaPolicy.create!(
      account: account, name: 'Padrão', conditions: [],
      targets: { 'default' => { 'first_response' => 60, 'next_response' => 120, 'resolution' => 480 },
                 'urgent' => { 'first_response' => 15 } }
    )
  end

  def new_conversation(priority: nil)
    create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox, priority: priority, status: :open)
  end

  it 'applies the first matching policy on creation with targets by priority' do
    conversation = new_conversation(priority: :urgent)
    applied = Staydesk::Sla::Applier.new(conversation).perform

    expect(applied.sla_policy).to eq(policy)
    expect(applied.first_response_due_at).to be_within(1.second).of(conversation.created_at + 15.minutes)
    expect(applied.resolution_due_at).to be_within(1.second).of(conversation.created_at + 480.minutes)
    expect(conversation.reload.custom_attributes).to include('sla_alvo' => 'Padrão', 'sla_status' => 'running')
  end

  it 'meets first response, restarts next response on contact messages and pauses on pending' do
    conversation = new_conversation
    Staydesk::Sla::Applier.new(conversation).perform
    tracker = Staydesk::Sla::Tracker.new(conversation)

    incoming = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, sender: contact)
    tracker.message_created(incoming)
    expect(tracker.applied.reload.next_response_due_at).to be_within(1.second).of(incoming.created_at + 120.minutes)

    reply = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing, sender: agent)
    tracker.message_created(reply)
    applied = tracker.applied.reload
    expect(applied.first_response_met_at).to be_within(1.second).of(reply.created_at)
    expect(applied.next_response_due_at).to be_nil

    paused_at = Time.current
    tracker.status_changed('open', 'pending', paused_at)
    expect(tracker.applied.reload.status).to eq('paused')

    due_before = tracker.applied.resolution_due_at
    tracker.status_changed('pending', 'open', paused_at + 30.minutes)
    applied = tracker.applied.reload
    expect(applied.status).to eq('running')
    expect(applied.resolution_due_at).to be_within(1.second).of(due_before + 30.minutes)
    expect(applied.paused_seconds).to eq(1800)

    tracker.status_changed('open', 'resolved')
    expect(tracker.applied.reload.status).to eq('met')
    expect(conversation.reload.custom_attributes['sla_status']).to eq('met')
  end

  it 'drops the SLA when no policy matches' do
    policy.update!(conditions: [{ 'attribute_key' => 'priority', 'filter_operator' => 'equal_to', 'values' => ['urgent'], 'query_operator' => nil }])
    conversation = new_conversation(priority: :low)

    expect(Staydesk::Sla::Applier.new(conversation).perform).to be_nil
    expect(Staydesk::AppliedSla.where(conversation: conversation)).to be_empty
  end
end

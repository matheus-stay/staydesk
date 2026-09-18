require 'rails_helper'

RSpec.describe Staydesk::Sla::CheckJob do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :open) }
  let(:policy) do
    Staydesk::SlaPolicy.create!(account: account, name: 'Padrão', conditions: [],
                                targets: { 'default' => { 'first_response' => 60 } }, warning_ratio: 0.5)
  end

  before { allow(Rails.configuration.dispatcher).to receive(:dispatch) }

  it 'warns once, then breaches once, recording events and attributes' do
    applied = Staydesk::AppliedSla.create!(account: account, conversation: conversation, sla_policy: policy,
                                           first_response_due_at: 20.minutes.from_now)

    described_class.perform_now
    expect(applied.reload).to have_attributes(status: 'warning', warned_metrics: ['first_response'])
    expect(Rails.configuration.dispatcher).to have_received(:dispatch).with('staydesk_sla.warning', anything,
                                                                            hash_including(metric: 'first_response')).once

    described_class.perform_now
    expect(Rails.configuration.dispatcher).to have_received(:dispatch).with('staydesk_sla.warning', anything, anything).once

    applied.update!(first_response_due_at: 1.minute.ago)
    described_class.perform_now
    expect(applied.reload).to have_attributes(status: 'breached', breached_metrics: ['first_response'])
    expect(Staydesk::ConversationEvent.where(conversation: conversation).pluck(:kind)).to contain_exactly('staydesk_sla_warning',
                                                                                                          'staydesk_sla_breached')
    expect(conversation.reload.custom_attributes['sla_status']).to eq('breached')
  end

  it 'ignores paused SLAs' do
    Staydesk::AppliedSla.create!(account: account, conversation: conversation, sla_policy: policy, status: 'paused',
                                 paused_at: Time.current, first_response_due_at: 1.minute.ago)

    described_class.perform_now

    expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(/staydesk_sla/, anything, anything)
  end
end

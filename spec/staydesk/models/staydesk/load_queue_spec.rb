require 'rails_helper'

RSpec.describe Staydesk::LoadQueue do
  let(:account) { create(:account) }
  let(:widget) { create(:inbox, account: account, channel: create(:channel_widget, account: account)) }
  let(:email) { create(:inbox, account: account, channel: create(:channel_email, account: account)) }
  let(:api) { create(:inbox, account: account, channel: create(:channel_api, account: account)) }

  it 'falls back to the product default when the account configured none' do
    expect(described_class.keys_for(account)).to eq(%w[chat ticket])
    expect(described_class.for_inbox(email).key).to eq('ticket')
    expect(described_class.for_inbox(widget).key).to eq('chat')
    expect(described_class.for_inbox(api).key).to eq('chat')
  end

  context 'with queues configured by the account' do
    before do
      described_class.create!(account: account, key: 'chat', name: 'Chat', catch_all: true, position: 0)
      described_class.create!(account: account, key: 'ticket', name: 'Tickets', position: 1,
                              channel_types: ['Channel::Email'], inbox_ids: [api.id])
    end

    it 'sends an inbox claimed by name to its queue even when the channel is shared' do
      expect(described_class.for_inbox(api).key).to eq('ticket')
      expect(described_class.for_inbox(email).key).to eq('ticket')
      expect(described_class.for_inbox(widget).key).to eq('chat')
    end

    it 'counts the load of each queue on its own inboxes' do
      agent = create(:user, account: account, role: :agent)
      create(:conversation, account: account, inbox: api, assignee: agent, status: 'open')
      create(:conversation, account: account, inbox: widget, assignee: agent, status: 'open')

      service = Staydesk::AgentLoadService.new(account)

      expect(service.load_by_user('ticket', [agent.id])).to eq(agent.id => 1)
      expect(service.load_by_user('chat', [agent.id])).to eq(agent.id => 1)
    end

    it 'keeps only the work channels the account knows, in queue order' do
      status = Staydesk::AgentStatus.create!(account: account, name: 'Disponível', availability: 'online',
                                             work_channels: %w[voz ticket chat])

      expect(status.reload.work_channels).to eq(%w[chat ticket])
    end
  end
end

require 'rails_helper'

RSpec.describe Staydesk::AgentLoadService do
  # A caixa só devolve quem está conectado: aqui todo mundo da conta está.
  before do
    allow(OnlineStatusTracker).to receive(:get_available_users) do
      account.users.pluck(:id).to_h { |id| [id.to_s, 'online'] }
    end
  end

  let(:account) { create(:account) }
  let(:chat_inbox) { create(:inbox, account: account) }
  let(:email_inbox) { create(:inbox, :with_email, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:account_user) { account.account_users.find_by(user: agent) }
  let(:service) { described_class.new(account) }

  def move_to(name, channels)
    status = Staydesk::AgentStatus.create!(account: account, name: name, work_channels: channels)
    Staydesk::AgentStatusService.new(account_user).change_to(status)
  end

  def regra(limites, padrao: true, agentes: [])
    Staydesk::CapacityRule.create!(account: account, name: "Regra #{limites}", limits: limites, is_default: padrao, user_ids: agentes)
  end

  def open_conversations(inbox, count)
    count.times { create(:conversation, account: account, inbox: inbox, assignee: agent, status: 'open') }
  end

  it 'splits the queues by channel type' do
    expect(described_class.queue_for(chat_inbox)).to eq('chat')
    expect(described_class.queue_for(email_inbox)).to eq('ticket')
  end

  it 'holds back an agent who reached the chat limit of the capacity rule' do
    regra({ 'chat' => 2 })
    move_to('Chat', %w[chat])
    open_conversations(chat_inbox, 1)

    expect(service.over_capacity(chat_inbox, [agent.id])).to be_empty

    open_conversations(chat_inbox, 1)

    expect(service.over_capacity(chat_inbox, [agent.id])).to eq([agent.id])
    expect(service.with_capacity(chat_inbox, [agent.id])).to be_empty
  end

  it 'counts only conversations being handled now' do
    regra({ 'chat' => 1 })
    move_to('Chat', %w[chat])
    create(:conversation, account: account, inbox: chat_inbox, assignee: agent, status: 'resolved')
    create(:conversation, account: account, inbox: chat_inbox, assignee: agent, status: 'snoozed')
    create(:conversation, account: account, inbox: chat_inbox, assignee: agent, status: 'pending')

    expect(service.load_by_user('chat', [agent.id])).to eq({})
    expect(service.over_capacity(chat_inbox, [agent.id])).to be_empty
  end

  it 'keeps the queues apart: tickets do not fill the chat limit' do
    regra({ 'chat' => 1, 'ticket' => 3 })
    move_to('Misto', %w[chat ticket])
    open_conversations(email_inbox, 3)

    expect(service.over_capacity(chat_inbox, [agent.id])).to be_empty
    expect(service.over_capacity(email_inbox, [agent.id])).to eq([agent.id])
  end

  it 'leaves an agent without limit when the rule says nothing about that queue' do
    regra({ 'ticket' => 1 })
    move_to('Tudo', %w[chat ticket])
    open_conversations(chat_inbox, 5)

    expect(service.over_capacity(chat_inbox, [agent.id])).to be_empty
  end

  it 'leaves an agent without a custom status or rule untouched' do
    open_conversations(chat_inbox, 9)

    expect(service.over_capacity(chat_inbox, [agent.id])).to be_empty
  end

  it 'never distributes a channel the status does not receive, whatever the rule says' do
    regra({ 'chat' => 3, 'ticket' => 10 })
    move_to('Só chat', %w[chat])

    expect(service.over_capacity(email_inbox, [agent.id])).to eq([agent.id])
    expect(service.over_capacity(chat_inbox, [agent.id])).to be_empty
  end

  it 'prefers the rule assigned to the agent over the default one' do
    regra({ 'chat' => 10 })
    regra({ 'chat' => 1 }, padrao: false, agentes: [agent.id])
    move_to('Chat', %w[chat])
    open_conversations(chat_inbox, 1)

    expect(service.over_capacity(chat_inbox, [agent.id])).to eq([agent.id])
  end

  it 'reports load, rule and limit per queue for the panel' do
    regra({ 'chat' => 4 })
    move_to('Misto', %w[chat ticket])
    open_conversations(chat_inbox, 2)
    open_conversations(email_inbox, 1)

    entry = service.summary([agent.id])[agent.id]

    expect(entry[:load]).to eq('chat' => 2, 'ticket' => 1)
    expect(entry[:capacity]).to eq('chat' => 4, 'ticket' => nil)
    expect(entry[:status].name).to eq('Misto')
    expect(entry[:rule].limits).to eq('chat' => 4)
  end

  it 'shows zero for a channel the status does not receive' do
    regra({ 'chat' => 4, 'ticket' => 9 })
    move_to('Só tickets', %w[ticket])

    expect(service.summary([agent.id])[agent.id][:capacity]).to eq('chat' => 0, 'ticket' => 9)
  end

  it 'takes the full agent out of the automatic distribution' do
    create(:inbox_member, inbox: chat_inbox, user: agent)
    regra({ 'chat' => 1 })
    move_to('Chat', %w[chat])

    expect(chat_inbox.member_ids_with_assignment_capacity).to eq([agent.id])

    open_conversations(chat_inbox, 1)

    expect(chat_inbox.member_ids_with_assignment_capacity).to be_empty
  end

  it 'keeps the full agent out of the available agents used by the newer distribution' do
    create(:inbox_member, inbox: chat_inbox, user: agent)
    regra({ 'chat' => 1 })
    move_to('Chat', %w[chat])
    allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ agent.id.to_s => 'online' })

    expect(chat_inbox.available_agents.map(&:user_id)).to eq([agent.id])

    open_conversations(chat_inbox, 1)

    expect(chat_inbox.available_agents).to be_empty
  end
end

require 'rails_helper'

RSpec.describe Staydesk::DistributionCheckService do
  let(:account) { create(:account) }
  let(:n2) { create(:team, account: account, name: 'suporte n2') }
  let(:email) { create(:inbox, account: account, channel: create(:channel_email, account: account)) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:account_user) { account.account_users.find_by(user: agent) }

  before do
    Staydesk::Queue.create!(account: account, name: 'Tickets', team: n2, channel_types: ['Channel::Email'], position: 0)
    so_tickets = Staydesk::AgentStatus.create!(account: account, name: 'Só tickets', availability: 'online',
                                               capacity: { 'chat' => 0, 'ticket' => 20 })
    Staydesk::AgentStatusService.new(account_user).change_to(so_tickets)
    allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ agent.id.to_s => 'online' })
  end

  def fila_do_agente
    described_class.new(account).perform.find { |linha| linha[:user_id] == agent.id }[:queues].first
  end

  it 'names what is missing for an agent who is online but outside the group and the inbox' do
    checks = fila_do_agente[:checks]

    expect(checks).to include(connected: true, available: true, has_capacity: true, in_group: false, inbox_member: false)
    expect(fila_do_agente[:receives]).to be(false)
  end

  it 'says the agent receives once the group and the inbox are in place' do
    create(:team_member, team: n2, user: agent)
    create(:inbox_member, inbox: email, user: agent)

    expect(fila_do_agente[:receives]).to be(true)
    expect(fila_do_agente).to include(load_queue: 'ticket', capacity: 20)
  end

  it 'flags the limit when the status does not take that queue' do
    create(:team_member, team: n2, user: agent)
    create(:inbox_member, inbox: email, user: agent)
    so_chat = Staydesk::AgentStatus.create!(account: account, name: 'Só chat', availability: 'online',
                                            capacity: { 'chat' => 6, 'ticket' => 0 })
    Staydesk::AgentStatusService.new(account_user).change_to(so_chat)

    expect(fila_do_agente[:checks][:has_capacity]).to be(false)
    expect(fila_do_agente[:receives]).to be(false)
  end
end

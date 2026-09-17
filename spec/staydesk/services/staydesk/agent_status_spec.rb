require 'rails_helper'

RSpec.describe 'StayDesk agent statuses' do
  let(:account) { create(:account) }
  let(:chat_inbox) { create(:inbox, account: account) }
  let(:ticket_inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:account_user) { account.account_users.find_by(user: agent) }
  let!(:chat_only) { Staydesk::AgentStatus.create!(account: account, name: 'Só chat', availability: 'online', inbox_ids: [chat_inbox.id]) }
  let!(:away) { Staydesk::AgentStatus.create!(account: account, name: 'Ausente', availability: 'busy') }

  before do
    create(:inbox_member, inbox: chat_inbox, user: agent)
    create(:inbox_member, inbox: ticket_inbox, user: agent)
    allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id).and_return({ agent.id.to_s => 'online' })
  end

  it 'opens and closes periods and aligns the Chatwoot availability' do
    service = Staydesk::AgentStatusService.new(account_user)

    service.change_to(chat_only, at: Time.zone.parse('2026-09-17 09:00'))
    service.change_to(away, at: Time.zone.parse('2026-09-17 12:00'))

    periods = Staydesk::AgentStatusPeriod.where(account_user: account_user).order(:id)
    expect(periods.first).to have_attributes(agent_status: chat_only, ended_at: Time.zone.parse('2026-09-17 12:00'))
    expect(periods.last).to have_attributes(agent_status: away, ended_at: nil)
    expect(service.current).to eq(away)
    expect(account_user.reload.availability).to eq('busy')
  end

  it 'keeps the agent out of inboxes the status does not serve' do
    Staydesk::AgentStatusService.new(account_user).change_to(chat_only)

    expect(chat_inbox.available_agents.map(&:user_id)).to eq([agent.id])
    expect(ticket_inbox.available_agents.map(&:user_id)).to be_empty
  end

  it 'does not restrict agents without a status or with an all-inbox status' do
    expect(ticket_inbox.available_agents.map(&:user_id)).to eq([agent.id])

    Staydesk::AgentStatusService.new(account_user).change_to(away)
    expect(ticket_inbox.available_agents.map(&:user_id)).to eq([agent.id])
  end
end

require 'rails_helper'

RSpec.describe Staydesk::MissedOffersService do
  let(:account) { create(:account) }
  let(:n1) { create(:team, account: account, name: 'suporte n1') }
  let(:chat) { create(:inbox, account: account) }
  let(:ana) { create(:user, account: account, role: :agent) }
  let(:vinculo) { account.account_users.find_by(user: ana) }
  let(:so_chat) { Staydesk::AgentStatus.create!(account: account, name: 'Só chat', availability: 'online', work_channels: %w[chat]) }
  let(:ausente) { Staydesk::AgentStatus.create!(account: account, name: 'Ausente', availability: 'busy', counts_as_online: false) }

  before do
    create(:team_member, team: n1, user: ana)
    Staydesk::Queue.create!(account: account, name: 'Chat', team: n1, position: 0, accept_required: true, accept_timeout_seconds: 30)
    Staydesk::CapacityRule.create!(account: account, name: 'Padrão', is_default: true, limits: { 'chat' => 10 },
                                   missed_offers_limit: 3, missed_offers_to_status: ausente)
    Staydesk::AgentStatusService.new(vinculo).change_to(so_chat)
    allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ ana.id.to_s => 'online' })
  end

  def perder_um
    conversation = create(:conversation, account: account, inbox: chat, team: n1)
    convite = Staydesk::Offer.pendentes.find_by(conversation: conversation, user: ana)
    convite.update!(expires_at: 1.minute.ago)
    Staydesk::Offers::ExpireJob.new.perform(convite.id)
    conversation
  end

  it 'drops the agent to the away status after N missed invites in a row and stops the online time' do
    2.times { perder_um }
    expect(Staydesk::AgentStatusService.new(vinculo).current).to eq(so_chat)

    perder_um

    expect(Staydesk::AgentStatusService.new(vinculo).current).to eq(ausente)
    expect(vinculo.reload.availability).to eq('busy')
    expect(Staydesk::Offer.pendentes.where(user: ana)).to be_empty
  end

  it 'counts only invites since the agent entered the current status' do
    2.times { perder_um }
    Staydesk::AgentStatusService.new(vinculo).change_to(so_chat)

    perder_um

    expect(Staydesk::AgentStatusService.new(vinculo).current).to eq(so_chat)
  end

  it 'does nothing when the rule is off' do
    Staydesk::CapacityRule.find_by(account: account, name: 'Padrão').update!(missed_offers_limit: nil)

    4.times { perder_um }

    expect(Staydesk::AgentStatusService.new(vinculo).current).to eq(so_chat)
  end
end

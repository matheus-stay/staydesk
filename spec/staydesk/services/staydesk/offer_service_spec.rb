require 'rails_helper'

RSpec.describe Staydesk::OfferService do
  let(:account) { create(:account) }
  let(:n1) { create(:team, account: account, name: 'suporte n1') }
  let(:chat) { create(:inbox, account: account) }
  let(:ana) { create(:user, account: account, role: :agent) }
  let(:bruno) { create(:user, account: account, role: :agent) }

  before do
    [ana, bruno].each do |agente|
      create(:team_member, team: n1, user: agente)
      create(:inbox_member, inbox: chat, user: agente)
    end
    Staydesk::Queue.create!(account: account, name: 'Chat', team: n1, position: 0,
                            accept_required: true, accept_timeout_seconds: 30)
  end

  def conversa_atribuida(agente = ana)
    create(:conversation, account: account, inbox: chat, team: n1).tap { |c| c.update!(assignee: agente) }
  end

  it 'offers the conversation to the agent instead of just handing it over' do
    conversation = conversa_atribuida

    convite = Staydesk::Offer.pendentes.find_by(conversation: conversation)
    expect(convite).to have_attributes(user_id: ana.id, status: 'pendente')
    expect(convite.segundos_restantes).to be_between(1, 30)
  end

  it 'keeps the conversation with the agent once accepted' do
    conversation = conversa_atribuida
    convite = Staydesk::Offer.pendentes.find_by(conversation: conversation)

    described_class.new(conversation).accept!(convite)

    expect(convite.reload.status).to eq('aceita')
    expect(conversation.reload.assignee).to eq(ana)
  end

  it 'gives the conversation back to the queue when the agent declines' do
    conversation = conversa_atribuida
    convite = Staydesk::Offer.pendentes.find_by(conversation: conversation)
    allow(OnlineStatusTracker).to receive(:get_available_users).and_return({})

    described_class.new(conversation).decline!(convite)

    expect(convite.reload.status).to eq('recusada')
    expect(conversation.reload.assignee).to be_nil
  end

  it 'expires on its own and does not go back to the same agent' do
    conversation = conversa_atribuida
    convite = Staydesk::Offer.pendentes.find_by(conversation: conversation)
    convite.update!(expires_at: 1.minute.ago)
    allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ bruno.id.to_s => 'online' })

    Staydesk::Offers::ExpireJob.new.perform(convite.id)

    expect(convite.reload.status).to eq('expirada')
    expect(conversation.reload.assignee).to eq(bruno)
  end

  it 'does not ask for acceptance on a queue that does not require it' do
    Staydesk::Queue.find_by(account: account, name: 'Chat').update!(accept_required: false)
    conversation = conversa_atribuida

    expect(Staydesk::Offer.where(conversation: conversation)).to be_empty
    expect(conversation.reload.assignee).to eq(ana)
  end
end

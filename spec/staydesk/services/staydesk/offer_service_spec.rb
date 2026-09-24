require 'rails_helper'

RSpec.describe Staydesk::OfferService do
  let(:account) { create(:account) }
  let(:n1) { create(:team, account: account, name: 'suporte n1') }
  # Distribuição desligada na caixa: estes testes acionam a distribuição na mão,
  # para escolher o agente. Ligada, a criação já convidaria alguém pelo rodízio.
  let(:chat) { create(:inbox, account: account, enable_auto_assignment: false) }
  let(:ana) { create(:user, account: account, role: :agent) }
  let(:bruno) { create(:user, account: account, role: :agent) }

  before do
    [ana, bruno].each { |agente| create(:team_member, team: n1, user: agente) }
    Staydesk::Queue.create!(account: account, name: 'Chat', team: n1, position: 0,
                            accept_required: true, accept_timeout_seconds: 30)
    online([ana, bruno])
  end

  def online(agentes)
    allow(OnlineStatusTracker).to receive(:get_available_users).and_return(agentes.to_h { |a| [a.id.to_s, 'online'] })
  end

  # A distribuição escolhe o agente e, na fila com aceite, convida em vez de atribuir.
  def distribuir(para: ana)
    create(:conversation, account: account, inbox: chat, team: n1).tap do |c|
      AutoAssignment::AgentAssignmentService.new(conversation: c, allowed_agent_ids: [para.id]).perform
    end
  end

  it 'offers the conversation instead of handing it over: nobody is assigned until acceptance' do
    conversation = distribuir

    convite = Staydesk::Offer.pendentes.find_by(conversation: conversation)
    expect(convite).to have_attributes(user_id: ana.id, status: 'pendente')
    expect(convite.segundos_restantes).to be_between(1, 30)
    expect(conversation.reload.assignee).to be_nil
  end

  it 'reserves the agent seat while the invite is pending' do
    distribuir
    carga = Staydesk::AgentLoadService.new(account).load_by_user('chat', [ana.id])

    expect(carga).to eq(ana.id => 1)
  end

  it 'gives the conversation to the agent once accepted' do
    conversation = distribuir
    convite = Staydesk::Offer.pendentes.find_by(conversation: conversation)

    described_class.new(conversation).accept!(convite)

    expect(convite.reload.status).to eq('aceita')
    expect(conversation.reload.assignee).to eq(ana)
  end

  it 'offers to the next agent when the first declines' do
    conversation = distribuir
    convite = Staydesk::Offer.pendentes.find_by(conversation: conversation)

    described_class.new(conversation).decline!(convite)

    expect(convite.reload.status).to eq('recusada')
    expect(conversation.reload.assignee).to be_nil
    expect(Staydesk::Offer.pendentes.find_by(conversation: conversation).user).to eq(bruno)
  end

  it 'expires on its own and goes to someone else' do
    conversation = distribuir
    convite = Staydesk::Offer.pendentes.find_by(conversation: conversation)
    convite.update!(expires_at: 1.minute.ago)

    Staydesk::Offers::ExpireJob.new.perform(convite.id)

    expect(convite.reload.status).to eq('expirada')
    expect(Staydesk::Offer.pendentes.find_by(conversation: conversation).user).to eq(bruno)
  end

  it 'offers again to the same agent when there is nobody else' do
    online([ana])
    conversation = distribuir
    convite = Staydesk::Offer.pendentes.find_by(conversation: conversation)
    convite.update!(expires_at: 1.minute.ago)

    Staydesk::Offers::ExpireJob.new.perform(convite.id)

    expect(convite.reload.status).to eq('expirada')
    expect(Staydesk::Offer.pendentes.find_by(conversation: conversation).user).to eq(ana)
  end

  it 'kills the invite if someone else took the conversation meanwhile' do
    conversation = distribuir
    convite = Staydesk::Offer.pendentes.find_by(conversation: conversation)
    conversation.update!(assignee: bruno)

    described_class.new(conversation).accept!(convite)

    expect(convite.reload.status).to eq('expirada')
    expect(conversation.reload.assignee).to eq(bruno)
  end

  it 'leaves a conversation with a pending invite alone: sweep and distribution do not offer it again' do
    conversation = distribuir
    antes = Staydesk::Offer.where(conversation: conversation).count

    Staydesk::Queues::SweepJob.new.perform(account.id)
    AutoAssignment::AgentAssignmentService.new(conversation: conversation.reload, allowed_agent_ids: [ana.id, bruno.id]).perform

    expect(Staydesk::Offer.where(conversation: conversation).count).to eq(antes)
    expect(Staydesk::Offer.pendentes.where(conversation: conversation).count).to eq(1)
  end

  it 'does not ask for acceptance on a queue that does not require it' do
    Staydesk::Queue.find_by(account: account, name: 'Chat').update!(accept_required: false)
    conversation = distribuir

    expect(Staydesk::Offer.where(conversation: conversation)).to be_empty
    expect(conversation.reload.assignee).to eq(ana)
  end

  it 'does not ask for acceptance on a manual assignment' do
    online([])
    conversation = create(:conversation, account: account, inbox: chat, team: n1)
    conversation.update!(assignee: ana)

    expect(Staydesk::Offer.where(conversation: conversation)).to be_empty
    expect(conversation.reload.assignee).to eq(ana)
  end

  it 'leaves the conversation in the queue when the queue says not to re-offer' do
    Staydesk::Queue.find_by(account: account, name: 'Chat').update!(reoffer_same_agent: false)
    online([ana])
    conversation = distribuir
    convite = Staydesk::Offer.pendentes.find_by(conversation: conversation)
    convite.update!(expires_at: 1.minute.ago)

    Staydesk::Offers::ExpireJob.new.perform(convite.id)

    expect(Staydesk::Offer.pendentes.where(conversation: conversation)).to be_empty
    expect(conversation.reload.assignee).to be_nil
  end
end

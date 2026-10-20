require 'rails_helper'

# A conversa que chega por um canal (e-mail, chat) nasce sem grupo. Se o grupo
# da fila só entrasse depois de gravada, a distribuição automática do produto,
# que dispara no mesmo save, entregaria o trabalho direto e o agente nunca
# veria o convite. O grupo tem que nascer com ela.
RSpec.describe 'conversa nova cai na fila antes de ser distribuída' do
  let(:account) { create(:account) }
  let(:n2) { create(:team, account: account, name: 'Suporte N2') }
  let(:email) { create(:inbox, account: account, channel: create(:channel_email, account: account)) }
  let(:ana) { create(:user, account: account, role: :agent) }

  before do
    create(:team_member, team: n2, user: ana)
    create(:inbox_member, inbox: email, user: ana)
    Staydesk::Queue.create!(account: account, name: 'Tickets', team: n2, position: 0,
                            accept_required: true, accept_timeout_seconds: 30,
                            channel_types: ['Channel::Email'])
  end

  it 'gives the conversation the queue group before it is saved' do
    conversation = create(:conversation, account: account, inbox: email, team: nil)

    expect(conversation.team).to eq(n2)
  end

  it 'invites instead of assigning when the queue requires acceptance' do
    allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ ana.id.to_s => 'online' })
    conversation = create(:conversation, account: account, inbox: email, team: nil)

    AutoAssignment::AgentAssignmentService.new(conversation: conversation, allowed_agent_ids: [ana.id]).perform

    expect(Staydesk::Offer.pendentes.find_by(conversation: conversation)).to be_present
    expect(conversation.reload.assignee).to be_nil
  end

  it 'finds the queue even when the caller holds a conversation loaded before the group was written' do
    conversation = create(:conversation, account: account, inbox: email, team: nil)
    desatualizada = Conversation.find(conversation.id)
    desatualizada.team_id = nil

    expect(Staydesk::Queue.da_conversa(desatualizada)&.name).to eq('Tickets')
  end

  it 'leaves the decision to the post-creation routing when a queue ahead depends on conditions' do
    Staydesk::Queue.create!(account: account, name: 'Urgentes', team: n2, position: -1,
                            channel_types: ['Channel::Email'],
                            conditions: [{ 'attribute_key' => 'priority', 'filter_operator' => 'equal_to', 'values' => ['urgent'] }])

    expect(Staydesk::QueueRouter.new(Conversation.new(account: account, inbox: email)).match_inline).to be_nil
  end

  # No staging, o ticket com fila que decide pelo assunto (N3) nascia sem grupo, e
  # a distribuição automática do produto, no mesmo save, entregava direto ao
  # agente: sem convite e fora da fila.
  context 'when the first queue decides by subject' do
    let(:n3) { create(:team, account: account, name: 'Suporte N3') }

    before do
      Staydesk::Queue.create!(account: account, name: 'Tickets N3', team: n3, position: -1, accept_required: true,
                              channel_types: ['Channel::Email'],
                              conditions: [{ 'attribute_key' => 'mail_subject', 'filter_operator' => 'contains', 'values' => ['malware'] }])
      allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ ana.id.to_s => 'online' })
    end

    it 'does not hand the ticket to anyone before the queue decides, and redistributes right after' do
      conversation = nil
      expect do
        conversation = create(:conversation, account: account, inbox: email, team: nil,
                                             additional_attributes: { 'mail_subject' => 'Dúvida sobre e-mail' })
      end.to have_enqueued_job(Staydesk::Queues::SweepJob)

      expect(conversation.reload).to have_attributes(assignee_id: nil, team_id: n2.id)
    end

    it 'waits for the routing instead of assigning a conversation without a group' do
      conversation = Conversation.new(account: account, inbox: email, team: nil)

      service = AutoAssignment::AgentAssignmentService.new(conversation: conversation, allowed_agent_ids: [ana.id])

      expect(service.find_assignee).to be_nil
    end
  end

  it 'moves the queue as soon as an agent frees a slot' do
    conversation = create(:conversation, account: account, inbox: email, team: n2, assignee: ana, status: :open)

    expect { conversation.update!(status: :resolved) }.to have_enqueued_job(Staydesk::Queues::SweepJob)
  end
end

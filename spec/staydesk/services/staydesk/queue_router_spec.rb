require 'rails_helper'

RSpec.describe Staydesk::QueueRouter do
  let(:account) { create(:account) }
  let(:n1) { create(:team, account: account, name: 'suporte n1') }
  let(:n2) { create(:team, account: account, name: 'suporte n2') }
  let(:n3) { create(:team, account: account, name: 'suporte n3') }
  let(:chat) { create(:inbox, account: account) }
  let(:email) { create(:inbox, :with_email, account: account) }

  def fila(nome, time, posicao, condicoes = [])
    Staydesk::Queue.create!(account: account, name: nome, team: time, position: posicao, conditions: condicoes)
  end

  def conversa(inbox: chat, **extra)
    create(:conversation, account: account, inbox: inbox, **extra)
  end

  it 'delivers to the team of the first queue that matches, in order' do
    fila('N3 por e-mail', n3, 0, [{ 'attribute_key' => 'inbox_id', 'filter_operator' => 'equal_to', 'values' => [email.id] }])
    fila('N2 urgente', n2, 1, [{ 'attribute_key' => 'priority', 'filter_operator' => 'equal_to', 'values' => ['urgent'] }])
    fila('N1 recolhe o resto', n1, 2)

    expect(conversa(inbox: email).reload.team).to eq(n3)
    expect(conversa(priority: :urgent).reload.team).to eq(n2)
    expect(conversa.reload.team).to eq(n1)
  end

  it 'does not touch a conversation that already has a team' do
    fila('N1 recolhe o resto', n1, 0)

    expect(conversa(team: n2).reload.team).to eq(n2)
  end

  it 'leaves the conversation without a team when no queue matches' do
    fila('Só e-mail', n3, 0, [{ 'attribute_key' => 'inbox_id', 'filter_operator' => 'equal_to', 'values' => [email.id] }])

    expect(conversa.reload.team).to be_nil
  end

  it 'skips an inactive queue' do
    fila('N3 por e-mail', n3, 0, [{ 'attribute_key' => 'inbox_id', 'filter_operator' => 'equal_to', 'values' => [email.id] }]).update!(active: false)
    fila('N1 recolhe o resto', n1, 1)

    expect(conversa(inbox: email).reload.team).to eq(n1)
  end

  it 'hands the conversation to the team before the agent is picked' do
    create(:inbox_member, inbox: chat, user: create(:user, account: account, role: :agent))
    fila('N1 recolhe o resto', n1, 0)

    conversation = conversa
    expect(conversation.reload.team).to eq(n1)
    expect(conversation.assignee).to be_nil.or be_present
  end

  describe 'transbordo' do
    # A caixa só devolve quem está conectado: aqui todo mundo da conta está.
    before do
      allow(OnlineStatusTracker).to receive(:get_available_users) do
        account.users.pluck(:id).to_h { |id| [id.to_s, 'online'] }
      end
    end

    let(:agente_n3) { create(:user, account: account, role: :agent) }
    let(:agente_n2) { create(:user, account: account, role: :agent) }

    def monta_transbordo(minutos: nil)
      Staydesk::Queue.create!(account: account, name: 'Tickets do N3', team: n3, fallback_team_ids: [n2.id],
                              fallback_after_minutes: minutos, position: 0)
      [[agente_n3, n3], [agente_n2, n2]].each do |usuario, time|
        create(:team_member, team: time, user: usuario)
        create(:inbox_member, inbox: chat, user: usuario)
      end
    end

    def elegiveis(conversation)
      Staydesk::QueueOverflow.new(conversation).eligible_user_ids(chat.member_ids_with_assignment_capacity)
    end

    it 'mantém a conversa no grupo dono e deixa só ele atender quando há gente' do
      monta_transbordo
      conversation = conversa

      expect(conversation.reload.team).to eq(n3)
      expect(elegiveis(conversation)).to eq([agente_n3.id])
    end

    it 'abre para o grupo secundário quando o principal não tem ninguém' do
      monta_transbordo
      conversation = conversa
      TeamMember.find_by(team: n3, user: agente_n3).destroy!

      expect(elegiveis(conversation.reload)).to eq([agente_n2.id])
      expect(conversation.team).to eq(n3)
    end

    it 'com espera configurada, só abre depois do tempo' do
      monta_transbordo(minutos: 10)
      conversation = conversa
      TeamMember.find_by(team: n3, user: agente_n3).destroy!

      expect(elegiveis(conversation.reload)).to be_empty

      conversation.update_columns(created_at: 20.minutes.ago)
      expect(elegiveis(conversation.reload)).to eq([agente_n2.id])
    end

    it 'com mais de um grupo principal, todos trabalham a fila juntos e a conversa entra no primeiro' do
      monta_transbordo
      Staydesk::Queue.find_by(name: 'Tickets do N3').update!(team_ids: [n3.id, n2.id], fallback_team_ids: [])
      conversation = conversa

      expect(conversation.reload.team).to eq(n3)
      expect(elegiveis(conversation)).to contain_exactly(agente_n3.id, agente_n2.id)
    end

    it 'não deixa um grupo ser principal e secundário ao mesmo tempo' do
      monta_transbordo
      fila = Staydesk::Queue.find_by(name: 'Tickets do N3')

      expect(fila.update(team_ids: [n3.id, n2.id])).to be(false)
      expect(fila.errors[:fallback_team_ids]).to be_present
    end

    it 'a conversa passa para o grupo de quem pegou, como no Zendesk' do
      monta_transbordo
      conversation = conversa
      TeamMember.find_by(team: n3, user: agente_n3).destroy!

      conversation.reload.update!(assignee: agente_n2)

      expect(conversation.reload.team).to eq(n2)
    end

    it 'quem pegou está no grupo em que a conversa entrou: ela fica lá' do
      monta_transbordo
      conversation = conversa

      conversation.reload.update!(assignee: agente_n3)

      expect(conversation.reload.team).to eq(n3)
    end

    it 'aceita mais de um grupo de transbordo' do
      monta_transbordo
      Staydesk::Queue.find_by(name: 'Tickets do N3').update!(fallback_team_ids: [n2.id, n1.id])
      agente_n1 = create(:user, account: account, role: :agent)
      create(:team_member, team: n1, user: agente_n1)
      create(:inbox_member, inbox: chat, user: agente_n1)
      conversation = conversa
      TeamMember.find_by(team: n3, user: agente_n3).destroy!

      expect(elegiveis(conversation.reload)).to contain_exactly(agente_n2.id, agente_n1.id)
    end

    it 'o job chama a distribuição depois da espera e a conversa vai para o grupo de quem pegou' do
      monta_transbordo(minutos: 10)
      conversation = conversa
      TeamMember.find_by(team: n3, user: agente_n3).destroy!
      conversation.update_columns(created_at: 20.minutes.ago, assignee_id: nil)
      allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ agente_n2.id.to_s => 'online' })

      Staydesk::Queues::SweepJob.new.perform

      conversation.reload
      expect(conversation.assignee).to eq(agente_n2)
      expect(conversation.team).to eq(n2)
    end
  end

  describe 'varredura da fila' do
    before do
      allow(OnlineStatusTracker).to receive(:get_available_users) do
        account.users.pluck(:id).to_h { |id| [id.to_s, 'online'] }
      end
    end

    it 'dá grupo e dono para quem ficou esperando sem fila' do
      agente = create(:user, account: account, role: :agent)
      create(:team_member, team: n1, user: agente)
      create(:inbox_member, inbox: chat, user: agente)
      conversation = conversa
      conversation.update_columns(team_id: nil, assignee_id: nil)
      fila('N1 recolhe o resto', n1, 0)

      Staydesk::Queues::SweepJob.new.perform(account.id)

      conversation.reload
      expect(conversation.team).to eq(n1)
      expect(conversation.assignee).to eq(agente)
    end

    it 'não mexe em conversa que já tem dono' do
      agente = create(:user, account: account, role: :agent)
      create(:team_member, team: n1, user: agente)
      create(:inbox_member, inbox: chat, user: agente)
      fila('N1 recolhe o resto', n1, 0)
      conversation = conversa
      conversation.update!(assignee: agente)

      expect { Staydesk::Queues::SweepJob.new.perform(account.id) }
        .not_to(change { conversation.reload.assignee_id })
    end
  end

  describe 'canal e caixa da fila' do
    let(:email) { create(:inbox, account: account, channel: create(:channel_email, account: account)) }

    it 'pega pelo canal, sem precisar listar caixa por caixa' do
      Staydesk::Queue.create!(account: account, name: 'Tickets', team: n2, position: 0,
                              channel_types: ['Channel::Email'])
      Staydesk::Queue.create!(account: account, name: 'Resto', team: n1, position: 1)

      conversa_email = create(:conversation, account: account, inbox: email)
      conversa_chat = create(:conversation, account: account, inbox: chat)

      expect(conversa_email.reload.team).to eq(n2)
      expect(conversa_chat.reload.team).to eq(n1)
    end

    it 'aceita a caixa avulsa, para o mesmo canal servir a coisas diferentes' do
      api = create(:inbox, account: account, channel: create(:channel_api, account: account))
      Staydesk::Queue.create!(account: account, name: 'Tickets', team: n2, position: 0,
                              channel_types: ['Channel::Email'], inbox_ids: [api.id])
      Staydesk::Queue.create!(account: account, name: 'Resto', team: n1, position: 1)

      expect(create(:conversation, account: account, inbox: api).reload.team).to eq(n2)
      expect(create(:conversation, account: account, inbox: chat).reload.team).to eq(n1)
    end

    it 'sem canal e sem caixa, a fila recolhe o que sobrou' do
      Staydesk::Queue.create!(account: account, name: 'Tickets', team: n2, position: 0,
                              channel_types: ['Channel::Email'])
      Staydesk::Queue.create!(account: account, name: 'Resto', team: n1, position: 1)

      expect(create(:conversation, account: account, inbox: chat).reload.team).to eq(n1)
    end
  end
end

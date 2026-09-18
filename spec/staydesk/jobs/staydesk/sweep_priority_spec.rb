require 'rails_helper'

RSpec.describe 'ordem de entrega da fila' do
  let(:account) { create(:account) }
  let(:n1) { create(:team, account: account, name: 'suporte n1') }
  let(:chat) { create(:inbox, account: account, channel: create(:channel_widget, account: account)) }
  let(:policy) { Staydesk::SlaPolicy.create!(account: account, name: 'Padrão', targets: { 'high' => { 'first_response' => 5 } }) }

  def conversa(created_at, prazo: nil)
    c = create(:conversation, account: account, inbox: chat, team: n1, status: 'open', created_at: created_at)
    c.update_columns(assignee_id: nil)
    if prazo
      Staydesk::AppliedSla.create!(account: account, conversation: c, sla_policy: policy, status: 'running',
                                   first_response_due_at: prazo)
    end
    c
  end

  def ordem
    Staydesk::Queues::SweepJob.new.send(:ordenar, account.conversations.open.where(assignee_id: nil).to_a).map(&:id)
  end

  it 'entrega por chegada quando a fila é assim' do
    Staydesk::Queue.create!(account: account, name: 'Chat', team: n1, position: 0, priority_mode: 'chegada')
    antiga = conversa(2.hours.ago, prazo: 10.minutes.from_now)
    nova = conversa(1.minute.ago, prazo: 5.minutes.from_now)

    expect(ordem).to eq([antiga.id, nova.id])
  end

  it 'entrega quem está mais perto de vencer quando a fila é por SLA' do
    Staydesk::Queue.create!(account: account, name: 'Chat', team: n1, position: 0, priority_mode: 'sla')
    antiga = conversa(2.hours.ago, prazo: 10.minutes.from_now)
    nova = conversa(1.minute.ago, prazo: 5.minutes.from_now)
    sem_sla = conversa(3.hours.ago)

    expect(ordem).to eq([nova.id, antiga.id, sem_sla.id])
  end

  it 'refuses a priority mode it does not know' do
    fila = Staydesk::Queue.new(account: account, name: 'X', team: n1, priority_mode: 'sorteio')

    expect(fila).not_to be_valid
  end
end

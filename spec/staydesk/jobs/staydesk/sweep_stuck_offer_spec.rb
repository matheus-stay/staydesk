require 'rails_helper'

# A conversa parada na fila do staging: entrou quando ninguém recebia e ficou lá.
# A varredura tem que oferecê-la a quem fica disponível depois, inclusive quando
# um convite antigo ficou pendente porque o vencimento dele se perdeu.
RSpec.describe 'varredura entrega o que ficou parado na fila' do
  let(:account) { create(:account) }
  let(:n1) { create(:team, account: account, name: 'Suporte N1') }
  let(:whatsapp) do
    create(:inbox, account: account, channel: create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false))
  end
  let(:ana) { create(:user, account: account, role: :agent) }

  before do
    create(:team_member, team: n1, user: ana)
    create(:inbox_member, inbox: whatsapp, user: ana)
    Staydesk::Queue.create!(account: account, name: 'Chat e WhatsApp', team: n1, position: 0,
                            accept_required: true, accept_timeout_seconds: 30)
  end

  def online(agentes)
    allow(OnlineStatusTracker).to receive(:get_available_users).and_return(agentes.to_h { |a| [a.id.to_s, 'online'] })
  end

  def parada_desde(quando)
    online([])
    create(:conversation, account: account, inbox: whatsapp, team: nil, status: :open, created_at: quando).tap do |c|
      expect(Staydesk::Offer.where(conversation: c)).to be_empty
    end
  end

  it 'offers a conversation that has been waiting for weeks once someone is available' do
    conversa = parada_desde(25.days.ago)

    online([ana])
    Staydesk::Queues::SweepJob.new.perform(account.id)

    expect(Staydesk::Offer.pendentes.find_by(conversation: conversa)).to have_attributes(user_id: ana.id)
    expect(conversa.reload.assignee).to be_nil
  end

  it 'expires an invite whose expiry was lost and offers the conversation again' do
    conversa = parada_desde(25.days.ago)
    esquecido = Staydesk::Offer.create!(account: account, conversation: conversa, user: ana, expires_at: 25.days.ago + 30.seconds)

    online([ana])
    Staydesk::Queues::SweepJob.new.perform(account.id)

    expect(esquecido.reload.status).to eq('expirada')
    expect(Staydesk::Offer.pendentes.find_by(conversation: conversa)).to be_present
  end

  it 'leaves an invite still within its time alone' do
    conversa = parada_desde(1.minute.ago)
    vigente = Staydesk::Offer.create!(account: account, conversation: conversa, user: ana, expires_at: 20.seconds.from_now)

    online([ana])
    Staydesk::Queues::SweepJob.new.perform(account.id)

    expect(vigente.reload.status).to eq('pendente')
    expect(Staydesk::Offer.where(conversation: conversa).count).to eq(1)
  end
end

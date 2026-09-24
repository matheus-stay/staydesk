require 'rails_helper'

# Os outros testes de convite chamam a distribuição na mão. Este exercita o
# caminho de verdade: conversa entra pelo canal e o Chatwoot é quem aciona a
# distribuição pelos próprios ganchos. É onde o convite estava sumindo.
RSpec.describe 'convite sai sozinho quando a conversa entra' do
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
    allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ ana.id.to_s => 'online' })
  end

  # A conta com a chave `assignment_v2` ligada desviava tudo para o job do
  # upstream: a conversa entrava na fila e ninguém era convidado, sem erro nenhum.
  it 'stays on the legacy path even when the account has assignment_v2 on' do
    account.enable_features('assignment_v2')
    account.save!

    expect(whatsapp.auto_assignment_v2_enabled?).to be(false)
  end

  it 'invites the available agent without anyone calling the distribution by hand' do
    conversation = create(:conversation, account: account, inbox: whatsapp, team: nil, status: :open)

    expect(conversation.reload.team).to eq(n1)
    expect(Staydesk::Offer.pendentes.find_by(conversation: conversation)).to be_present
    expect(conversation.assignee).to be_nil
  end
end

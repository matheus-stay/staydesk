require 'rails_helper'

# O convite precisa nascer mesmo com os outros ganchos da conversa salvando de
# novo (status ao atribuir, grupo de quem pegou), e o status só muda no aceite.
RSpec.describe 'convite de atendimento com status ao atribuir' do
  let(:account) { create(:account) }
  let(:n1) { create(:team, account: account, name: 'suporte n1') }
  let(:chat) { create(:inbox, account: account) }
  let(:ana) { create(:user, account: account, role: :agent) }
  before do
    Staydesk::TicketStatus.create!(account: account, name: 'Novo', base_status: 'open', default_for_base: true)
    Staydesk::TicketStatus.create!(account: account, name: 'Em andamento', base_status: 'open', apply_on_assign: true)
    create(:team_member, team: n1, user: ana)
    Staydesk::Queue.create!(account: account, name: 'Chat', team: n1, position: 0, accept_required: true, accept_timeout_seconds: 30)
    Staydesk::Queue.create!(account: account, name: 'Tickets', team: create(:team, account: account, name: 'n2'), position: 1)
  end

  def status_de(conversation)
    Staydesk::TicketStatusService.new(conversation.reload).current&.name
  end

  it 'creates the offer on assignment and only moves the status when the agent accepts' do
    conversation = create(:conversation, account: account, inbox: chat, team: n1)
    conversation.update!(assignee: ana)

    convite = Staydesk::Offer.pendentes.find_by(conversation: conversation)
    expect(convite).to be_present
    expect(status_de(conversation)).not_to eq('Em andamento')

    Staydesk::OfferService.new(conversation.reload).accept!(convite)

    expect(status_de(conversation)).to eq('Em andamento')
  end

  it 'still moves the status on assignment when the queue does not require acceptance' do
    n2 = account.teams.find_by(name: 'n2')
    create(:team_member, team: n2, user: ana)
    conversation = create(:conversation, account: account, inbox: chat, team: n2)
    conversation.update!(assignee: ana)

    expect(Staydesk::Offer.where(conversation: conversation)).to be_empty
    expect(status_de(conversation)).to eq('Em andamento')
  end
end

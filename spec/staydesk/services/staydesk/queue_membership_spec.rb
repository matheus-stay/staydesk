require 'rails_helper'

RSpec.describe Staydesk::QueueMembership do
  let(:account) { create(:account) }
  let(:n1) { create(:team, account: account, name: 'Suporte N1') }
  let(:n2) { create(:team, account: account, name: 'Suporte N2') }
  let(:chat) { create(:inbox, account: account) }
  let(:email) { create(:inbox, account: account, channel: create(:channel_email, account: account)) }
  let(:ana) { create(:user, account: account, role: :agent) }
  let(:bruno) { create(:user, account: account, role: :agent) }

  before do
    create(:team_member, team: n1, user: ana)
    create(:team_member, team: n2, user: bruno)
  end

  def fila(nome, time, canais, secundarios: [])
    Staydesk::Queue.create!(account: account, name: nome, team: time, team_ids: [time.id], channel_types: canais,
                            fallback_team_ids: secundarios.map(&:id), position: Staydesk::Queue.count)
  end

  it 'puts the queue groups in the channels the queue takes, and nobody else' do
    [chat, email]
    fila('Chat', n1, ['Channel::WebWidget'])
    fila('Tickets', n2, ['Channel::Email'])

    described_class.sync!(account)

    expect(chat.reload.members).to contain_exactly(ana)
    expect(email.reload.members).to contain_exactly(bruno)
  end

  it 'counts the secondary groups too' do
    [chat, email]
    fila('Chat', n1, ['Channel::WebWidget'], secundarios: [n2])

    described_class.sync!(account)

    expect(chat.reload.members).to contain_exactly(ana, bruno)
  end

  it 'takes someone out of the channel once they leave the group' do
    [chat, email]
    fila('Chat', n1, ['Channel::WebWidget'])
    described_class.sync!(account)
    TeamMember.where(team: n1, user: ana).destroy_all

    described_class.sync!(account)

    expect(chat.reload.members).to be_empty
  end

  it 'leaves an account without queues alone' do
    create(:inbox_member, inbox: chat, user: ana)
    create(:inbox_member, inbox: chat, user: bruno)

    expect(described_class.sync!(account)).to eq(adicionados: 0, removidos: 0)
    expect(chat.reload.members).to contain_exactly(ana, bruno)
  end
end

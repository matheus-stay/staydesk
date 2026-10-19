require 'rails_helper'

RSpec.describe Staydesk::ChannelMembership do
  let(:account) { create(:account) }

  it 'puts a new agent in every channel of the account' do
    canal = create(:inbox, account: account)
    agente = create(:user, account: account, role: :agent)

    expect(canal.reload.members).to include(agente)
  end

  it 'gives a new channel every agent of the account' do
    agente = create(:user, account: account, role: :agent)
    canal = create(:inbox, account: account)

    expect(canal.reload.members).to include(agente)
  end

  it 'lets the inbox wizard add someone who is already in without failing' do
    agente = create(:user, account: account, role: :agent)
    canal = create(:inbox, account: account)

    expect { canal.add_members([agente.id]) }.not_to raise_error
    expect(canal.inbox_members.where(user_id: agente.id).count).to eq(1)
  end

  # A tela de agentes do canal manda a lista escolhida e o Chatwoot tiraria quem
  # ficou de fora; quem é da conta fica.
  it 'keeps account agents when the channel screen sends a shorter list' do
    agente = create(:user, account: account, role: :agent)
    canal = create(:inbox, account: account)

    canal.remove_members([agente.id])

    expect(canal.reload.members).to include(agente)
  end

  it 'still drops someone who is no longer in the account' do
    agente = create(:user, account: account, role: :agent)
    canal = create(:inbox, account: account)
    account.account_users.where(user: agente).delete_all

    canal.remove_members([agente.id])

    expect(canal.reload.members).not_to include(agente)
  end

  it 'fills the gaps left by a manual removal' do
    agente = create(:user, account: account, role: :agent)
    canal = create(:inbox, account: account)
    canal.inbox_members.where(user_id: agente.id).destroy_all

    expect(described_class.sync!(account)).to eq(1)
    expect(canal.reload.members).to include(agente)
  end
end

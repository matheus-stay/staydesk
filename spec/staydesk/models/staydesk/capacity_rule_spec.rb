require 'rails_helper'

RSpec.describe Staydesk::CapacityRule do
  let(:account) { create(:account) }
  let(:ana) { create(:user, account: account, role: :agent) }
  let(:bia) { create(:user, account: account, role: :agent) }

  it 'keeps a single default rule per account' do
    primeira = described_class.create!(account: account, name: 'Padrão', is_default: true)
    described_class.create!(account: account, name: 'Nova padrão', is_default: true)

    expect(primeira.reload.is_default).to be(false)
  end

  it 'gives each agent one rule: joining a rule leaves the others' do
    antiga = described_class.create!(account: account, name: 'N1', user_ids: [ana.id, bia.id])
    described_class.create!(account: account, name: 'N3', user_ids: [ana.id])

    expect(antiga.reload.user_ids).to eq([bia.id])
  end

  it 'falls back to the default rule for an agent without one' do
    padrao = described_class.create!(account: account, name: 'Padrão', is_default: true, limits: { 'chat' => 4 })
    propria = described_class.create!(account: account, name: 'N3', user_ids: [ana.id], limits: { 'chat' => 1 })

    expect(described_class.for_user(account, ana.id)).to eq(propria)
    expect(described_class.for_user(account, bia.id)).to eq(padrao)
    expect(described_class.by_user(account, [ana.id, bia.id])).to eq(ana.id => propria, bia.id => padrao)
  end

  it 'keeps only limits of channels the account knows and treats blank as no limit' do
    regra = described_class.create!(account: account, name: 'X', limits: { 'chat' => '3', 'ticket' => '', 'voz' => 2 })

    expect(regra.limits).to eq('chat' => 3)
    expect(regra.limit_for('ticket')).to be_nil
    expect(regra.limit_for('chat')).to eq(3)
  end

  it 'rejects agents from another account' do
    outro = create(:user, account: create(:account), role: :agent)
    regra = described_class.new(account: account, name: 'X', user_ids: [outro.id])

    expect(regra).not_to be_valid
  end
end

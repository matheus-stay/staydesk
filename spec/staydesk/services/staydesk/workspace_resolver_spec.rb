require 'rails_helper'

RSpec.describe Staydesk::WorkspaceResolver do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:n1) { create(:team, account: account, name: 'n1') }
  let(:financeiro) { create(:team, account: account, name: 'financeiro') }

  def resolve(user)
    described_class.new(user: user, account: account).resolve
  end

  it 'falls back to the product default' do
    expect(resolve(agent)).to include('role' => 'agent', 'team_ids' => [])
    expect(resolve(agent)['list']).to include('layout' => 'cards')
    expect(resolve(agent)['menu']).to include('Conversation', 'Reports')
  end

  it 'layers the account default, the user teams and the role' do
    Staydesk::TeamWorkspace.create!(account: account, team_id: nil,
                                    config: { 'menu' => %w[Conversation Contacts], 'list' => { 'layout' => 'table' },
                                              'roles' => { 'administrator' => { 'menu' => %w[Conversation Contacts Reports] } } })
    Staydesk::TeamWorkspace.create!(account: account, team: n1, config: { 'list' => { 'columns' => %w[status subject] } })
    Staydesk::TeamWorkspace.create!(account: account, team: financeiro, config: { 'list' => { 'columns' => %w[subject contact] }, 'menu' => ['Reports'] })
    create(:team_member, team: n1, user: agent)
    create(:team_member, team: financeiro, user: agent)
    create(:team_member, team: n1, user: admin)

    agent_workspace = resolve(agent)
    expect(agent_workspace['list']).to include('layout' => 'table', 'columns' => %w[status subject contact])
    expect(agent_workspace['menu']).to eq(%w[Conversation Contacts Reports])
    expect(agent_workspace['team_ids']).to contain_exactly(n1.id, financeiro.id)

    expect(resolve(admin)['menu']).to eq(%w[Conversation Contacts Reports])
    expect(resolve(admin)['role']).to eq('administrator')
  end
end

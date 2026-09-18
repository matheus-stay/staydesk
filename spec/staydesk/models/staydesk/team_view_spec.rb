require 'rails_helper'

RSpec.describe Staydesk::TeamView do
  let(:account) { create(:account) }
  let(:team) { create(:team, account: account) }
  let(:other_team) { create(:team, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:query) { { 'payload' => [{ 'attribute_key' => 'status', 'filter_operator' => 'equal_to', 'values' => ['open'] }] } }

  describe 'validations' do
    it 'requires a payload array in the query' do
      view = described_class.new(account: account, name: 'Fila', query: { 'foo' => 'bar' })

      expect(view).not_to be_valid
      expect(view.errors[:query]).to be_present
    end

    it 'rejects unknown columns and sort options' do
      view = described_class.new(account: account, name: 'Fila', query: query, columns: ['nope'], sort_by: 'nope')

      expect(view).not_to be_valid
      expect(view.errors.attribute_names).to include(:columns, :sort_by)
    end
  end

  describe '.visible_to' do
    let!(:for_team) { described_class.create!(account: account, name: 'Do time', query: query, team_ids: [team.id]) }
    let!(:for_other) { described_class.create!(account: account, name: 'De outro', query: query, team_ids: [other_team.id]) }
    let!(:for_everyone) { described_class.create!(account: account, name: 'Todos', query: query) }

    it 'returns the views of the user teams plus the account-wide ones' do
      create(:team_member, team: team, user: agent)

      expect(described_class.visible_to(agent, account)).to contain_exactly(for_team, for_everyone)
    end

    it 'returns only account-wide views for a user without teams' do
      expect(described_class.visible_to(agent, account)).to contain_exactly(for_everyone)
    end
  end

  describe 'marcador do usuário atual' do
    let(:agent) { create(:user, account: account, role: :agent) }

    it 'swaps me for the id of whoever is asking' do
      view = described_class.create!(
        account: account, name: 'Minhas',
        query: { 'payload' => [{ 'attribute_key' => 'assignee_id', 'filter_operator' => 'equal_to', 'values' => ['me'] }] }
      )

      expect(view.payload(agent).first['values']).to eq([agent.id])
      expect(view.payload.first['values']).to eq(['me'])
    end

    it 'leaves other filters alone' do
      view = described_class.create!(
        account: account, name: 'Abertas',
        query: { 'payload' => [{ 'attribute_key' => 'status', 'filter_operator' => 'equal_to', 'values' => ['open'] }] }
      )

      expect(view.payload(agent).first['values']).to eq(['open'])
    end
  end
end

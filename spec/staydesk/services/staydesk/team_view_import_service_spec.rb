require 'rails_helper'

RSpec.describe Staydesk::TeamViewImportService do
  let(:account) { create(:account) }
  let!(:team) { create(:team, account: account, name: 'suporte n1') }
  let(:definitions) do
    [
      { 'name' => 'Fila - Tickets', 'color' => '#22c55e', 'teams' => ['Suporte N1'], 'sort_by' => 'waiting_since_desc',
        'query' => { 'payload' => [{ 'attribute_key' => 'status', 'filter_operator' => 'equal_to', 'values' => ['open'] }] } }
    ]
  end

  it 'creates the views resolving teams by name' do
    views = described_class.new(account: account, definitions: definitions).perform

    expect(views.first).to have_attributes(name: 'Fila - Tickets', team_ids: [team.id], position: 0, columns: Staydesk::TeamView::DEFAULT_COLUMNS)
  end

  it 'updates an existing view with the same name instead of duplicating it' do
    2.times { described_class.new(account: account, definitions: definitions).perform }

    expect(Staydesk::TeamView.where(account: account).count).to eq(1)
  end
  it 'finds the group by name without caring about capitals' do
    lideranca = create(:team, account: account, name: 'Tech Lead')
    described_class.new(account: account, definitions: [{ 'name' => 'Fila', 'teams' => ['tech lead'], 'query' => { 'payload' => [] } }]).perform

    expect(Staydesk::TeamView.find_by(account: account, name: 'Fila').team_ids).to eq([lideranca.id])
  end
end

require 'rails_helper'

# A fila de chat não pode nascer amarrada às caixas que existiam no dia da
# importação: canal novo (um WhatsApp, por exemplo) apareceria em lugar nenhum
# até alguém lembrar de citá-lo no arquivo. `caixas_exceto` inverte a regra e
# acompanha a fila de carga coringa, que é quem de fato recebe o que sobra.
RSpec.describe Staydesk::ConfigImportService do
  let(:account) { create(:account) }
  let!(:chat) { create(:inbox, account: account, name: 'Chat do site') }
  let!(:email) { create(:inbox, account: account, name: 'E-mail Suporte', channel: create(:channel_email, account: account)) }

  def importar(visualizacoes)
    described_class.new(account: account, config: { 'visualizacoes' => visualizacoes }).perform
  end

  def consulta_de(nome)
    Staydesk::TeamView.find_by(account: account, name: nome).query['payload']
  end

  def base(extra)
    { 'nome' => 'Fila', 'colunas' => %w[status subject],
      'consulta' => [{ 'attribute_key' => 'status', 'filter_operator' => 'equal_to', 'values' => ['open'] }] }.merge(extra)
  end

  it 'turns listed inboxes into an equal_to row' do
    importar([base('caixas' => ['Chat do site'])])

    expect(consulta_de('Fila').first).to include(
      'attribute_key' => 'inbox_id', 'filter_operator' => 'equal_to', 'values' => [chat.id]
    )
  end

  it 'turns excluded inboxes into a not_equal_to row, so a new channel shows up on its own' do
    importar([base('caixas_exceto' => ['E-mail Suporte'])])

    expect(consulta_de('Fila').first).to include(
      'attribute_key' => 'inbox_id', 'filter_operator' => 'not_equal_to', 'values' => [email.id]
    )
  end

  it 'keeps the view unfiltered by inbox when neither key is given' do
    importar([base({})])

    expect(consulta_de('Fila').map { |linha| linha['attribute_key'] }).to eq(['status'])
  end

  it 'turns named groups into a team condition, which is what the engineering view needs' do
    tech = create(:team, account: account, name: 'Tech')
    importar([base('grupos' => ['Tech'])])

    expect(consulta_de('Fila').first).to include(
      'attribute_key' => 'team_id', 'filter_operator' => 'equal_to', 'values' => [tech.id]
    )
  end

  it 'refuses a view that lists inboxes and exclusions at the same time' do
    expect { importar([base('caixas' => ['Chat do site'], 'caixas_exceto' => ['E-mail Suporte'])]) }
      .to raise_error(ArgumentError, /caixas.*caixas_exceto/)
  end
end

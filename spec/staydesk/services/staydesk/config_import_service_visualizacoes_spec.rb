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

  # A caixa de API do staging caiu na fila de chat porque a visualização dizia
  # "tudo menos os e-mails". O canal de trabalho segue as filas de carga, como a
  # distribuição, e é resolvido na hora da consulta.
  describe 'canais_de_trabalho' do
    before do
      Staydesk::LoadQueue.create!(account: account, key: 'chat', name: 'Chat', catch_all: true, position: 0)
      Staydesk::LoadQueue.create!(account: account, key: 'ticket', name: 'Tickets', channel_types: %w[Channel::Email Channel::Api], position: 1)
    end

    it 'stores the work channel, not inbox ids' do
      importar([base('canais_de_trabalho' => ['chat'])])

      expect(consulta_de('Fila').first).to include('attribute_key' => 'staydesk_load_queue', 'values' => ['chat'])
    end

    it 'resolves to the inboxes of that work channel when queried, including ones created later' do
      importar([base('canais_de_trabalho' => ['chat']), base('nome' => 'Tickets', 'canais_de_trabalho' => ['ticket'])])
      api = create(:inbox, account: account, name: 'Integração', channel: create(:channel_api, account: account))

      chat_view = Staydesk::TeamView.find_by(account: account, name: 'Fila')
      ticket_view = Staydesk::TeamView.find_by(account: account, name: 'Tickets')

      expect(chat_view.payload.first).to include('attribute_key' => 'inbox_id', 'values' => [chat.id])
      expect(ticket_view.payload.first['values']).to include(email.id, api.id)
      expect(ticket_view.payload.first['values']).not_to include(chat.id)
    end

    it 'refuses a view that mixes work channels and inboxes' do
      expect { importar([base('canais_de_trabalho' => ['chat'], 'caixas' => ['Chat do site'])]) }
        .to raise_error(ArgumentError, /canais_de_trabalho/)
    end
  end
end

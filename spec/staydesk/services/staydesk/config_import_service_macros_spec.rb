require 'rails_helper'

# As macros do Zendesk entram pelo arquivo, com grupo, status do ticket e agente
# pelo nome, e os gatilhos usam o mesmo caminho.
RSpec.describe Staydesk::ConfigImportService do
  let(:account) { create(:account) }
  let!(:n2) { create(:team, account: account, name: 'Suporte N2') }
  let!(:pendente) { Staydesk::TicketStatus.create!(account: account, name: 'Pendente', base_status: 'snoozed') }
  let!(:daniel) { create(:user, account: account, email: 'daniel@staycloud.com.br', role: :agent) }

  def importar(config)
    described_class.new(account: account, config: config).perform
  end

  it 'imports a macro resolving group and ticket status by name' do
    importar('macros' => [{ 'nome' => 'Devolver pra fila (N2)', 'acoes' => [
               { 'tipo' => 'assign_team', 'valor' => 'Suporte N2' }, { 'tipo' => 'staydesk_set_ticket_status', 'valor' => 'Pendente' },
               { 'tipo' => 'send_message', 'valor' => 'Olá {{contact.first_name}}' }, { 'tipo' => 'assign_team', 'valor' => 'Não existe' }
             ] }])

    macro = account.macros.find_by(name: 'Devolver pra fila (N2)')
    expect(macro).to be_global
    expect(macro.actions).to eq([
                                  { 'action_name' => 'assign_team', 'action_params' => [n2.id] },
                                  { 'action_name' => 'staydesk_set_ticket_status', 'action_params' => [pendente.id] },
                                  { 'action_name' => 'send_message', 'action_params' => ['Olá {{contact.first_name}}'] }
                                ])
  end

  it 'updates the same macro on a second import instead of duplicating it' do
    2.times { importar('macros' => [{ 'nome' => 'Malware', 'acoes' => [{ 'tipo' => 'send_message', 'valor' => 'x' }] }]) }

    expect(account.macros.where(name: 'Malware').count).to eq(1)
  end

  it 'builds a trigger with several conditions joined by AND and an agent by e-mail' do
    importar('automacoes' => [{ 'nome' => 'Cancelamento', 'evento' => 'conversation_created',
                                'condicoes' => [{ 'attribute_key' => 'mail_subject', 'filter_operator' => 'contains', 'values' => %w[cancelar] },
                                                { 'attribute_key' => 'priority', 'filter_operator' => 'equal_to', 'values' => %w[urgent] }],
                                'acoes' => [{ 'tipo' => 'assign_agent', 'valor' => 'daniel@staycloud.com.br' }] }])

    regra = AutomationRule.find_by(account: account, name: 'Cancelamento')
    expect(regra.conditions.first['query_operator']).to eq('AND')
    expect(regra.conditions.last).not_to have_key('query_operator')
    expect(regra.actions).to eq([{ 'action_name' => 'assign_agent', 'action_params' => [daniel.id] }])
  end
end

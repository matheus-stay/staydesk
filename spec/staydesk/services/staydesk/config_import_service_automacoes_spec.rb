require 'rails_helper'

# O gatilho que avisa o cliente que o chamado chegou, como no Zendesk. O número
# do ticket entra por variável, resolvida pelo produto na hora do envio.
RSpec.describe Staydesk::ConfigImportService do
  let(:account) { create(:account, locale: 'pt_BR') }
  let!(:email) { create(:inbox, account: account, name: 'E-mail Suporte', channel: create(:channel_email, account: account)) }
  let(:texto) do
    'Olá! O seu ticket #{{conversation.display_id}} já foi recebido e está sendo tratado pelo nosso time.'
  end

  def importar(automacoes)
    described_class.new(account: account, config: { 'automacoes' => automacoes }).perform
  end

  it 'creates the trigger bound to the channels it names' do
    importar([{ 'nome' => 'Confirmação de recebimento', 'evento' => 'conversation_created',
                'caixas' => ['E-mail Suporte'], 'acoes' => [{ 'tipo' => 'send_message', 'valores' => [texto] }] }])

    regra = AutomationRule.find_by(account: account, name: 'Confirmação de recebimento')
    expect(regra.event_name).to eq('conversation_created')
    expect(regra.conditions).to eq([{ 'attribute_key' => 'inbox_id', 'filter_operator' => 'equal_to', 'values' => [email.id] }])
    expect(regra.actions).to eq([{ 'action_name' => 'send_message', 'action_params' => [texto] }])
    expect(regra).to be_active
  end

  it 'deactivates a trigger whose channels do not exist yet' do
    resumo = importar([{ 'nome' => 'Aviso do WhatsApp', 'caixas' => ['WhatsApp Suporte'],
                         'acoes' => [{ 'tipo' => 'send_message', 'valores' => ['oi'] }] }])

    expect(AutomationRule.find_by(account: account, name: 'Aviso do WhatsApp')).not_to be_active
    expect(resumo[:automacoes].first).to include('desativada')
  end

  it 'is idempotent' do
    2.times do
      importar([{ 'nome' => 'Confirmação de recebimento', 'caixas' => ['E-mail Suporte'],
                  'acoes' => [{ 'tipo' => 'send_message', 'valores' => [texto] }] }])
    end

    expect(AutomationRule.where(account: account).count).to eq(1)
  end

  it 'turns the ticket number into the real number when the message goes out' do
    conversation = create(:conversation, account: account, inbox: email)
    mensagem = conversation.messages.create!(account: account, inbox: email, message_type: :outgoing, content: texto)

    expect(mensagem.content).to include("ticket ##{conversation.display_id}")
    expect(mensagem.content).not_to include('{{')
  end
end

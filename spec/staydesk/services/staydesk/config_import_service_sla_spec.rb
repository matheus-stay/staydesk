require 'rails_helper'

# A política de SLA que vale só para um canal precisa dizer isso em condição:
# política sem condição casa com qualquer conversa, e a primeira da ordem
# levaria as dos outros canais junto (o ticket de e-mail pegando o SLA do chat).
RSpec.describe Staydesk::ConfigImportService do
  let(:account) { create(:account) }
  let!(:chat) { create(:inbox, account: account, name: 'Chat do site') }
  let!(:email) { create(:inbox, account: account, name: 'E-mail Suporte', channel: create(:channel_email, account: account)) }

  def importar(politicas)
    described_class.new(account: account, config: { 'politicas_de_sla' => politicas }).perform
  end

  it 'turns channels and inboxes into one channel condition' do
    importar([{ 'nome' => 'SLA - Chat', 'canais' => ['Channel::WebWidget'], 'alvos' => { 'default' => { 'first_response' => 5 } } },
              { 'nome' => 'SLA - Ticket', 'caixas' => ['E-mail Suporte'], 'alvos' => { 'default' => { 'first_response' => 150 } } }])

    chat_policy = Staydesk::SlaPolicy.find_by(account: account, name: 'SLA - Chat')
    ticket_policy = Staydesk::SlaPolicy.find_by(account: account, name: 'SLA - Ticket')

    condicao = { 'attribute_key' => 'staydesk_channel', 'filter_operator' => 'equal_to' }
    expect(chat_policy.conditions).to eq([condicao.merge('values' => ['Channel::WebWidget'])])
    expect(ticket_policy.conditions).to eq([condicao.merge('values' => [email.id])])
  end

  it 'keeps a policy without channels matching everything' do
    importar([{ 'nome' => 'Sem SLA', 'condicoes' => [{ 'attribute_key' => 'labels', 'filter_operator' => 'equal_to', 'values' => ['remover_sla'] }],
                'alvos' => { 'default' => { 'first_response' => 525_600 } } }])

    expect(Staydesk::SlaPolicy.find_by(account: account, name: 'Sem SLA').conditions.map { |c| c['attribute_key'] }).to eq(['labels'])
  end

  it 'deactivates a policy whose channels do not exist yet and says so' do
    resumo = importar([{ 'nome' => 'SLA - WhatsApp', 'caixas' => ['WhatsApp Suporte'], 'alvos' => { 'default' => { 'first_response' => 5 } } }])

    expect(Staydesk::SlaPolicy.find_by(account: account, name: 'SLA - WhatsApp')).not_to be_active
    expect(resumo[:politicas_de_sla].first).to include('desativada')
  end

  it 'picks the ticket policy for an e-mail conversation, not the chat one' do
    importar([{ 'nome' => 'SLA - Chat', 'canais' => ['Channel::WebWidget'], 'alvos' => { 'default' => { 'first_response' => 5 } } },
              { 'nome' => 'SLA - Ticket', 'caixas' => ['E-mail Suporte'], 'alvos' => { 'default' => { 'first_response' => 150 } } }])
    conversation = create(:conversation, account: account, inbox: email)

    expect(Staydesk::Sla::PolicyMatcher.new(conversation).perform&.name).to eq('SLA - Ticket')
  end

  # A caixa de WhatsApp e a de API foram criadas depois da importação e ficaram
  # sem SLA no teste do staging: o canal precisa ser resolvido na hora.
  it 'covers an inbox created after the policy was imported' do
    importar([{ 'nome' => 'SLA - Ticket', 'canais' => ['Channel::Email', 'Channel::Api'], 'alvos' => { 'default' => { 'first_response' => 150 } } }])
    api = create(:inbox, account: account, name: 'Integração', channel: create(:channel_api, account: account))
    conversation = create(:conversation, account: account, inbox: api)

    expect(Staydesk::SlaPolicy.find_by(account: account, name: 'SLA - Ticket')).to be_active
    expect(Staydesk::Sla::PolicyMatcher.new(conversation).perform&.name).to eq('SLA - Ticket')
  end

  it 'does not match a channel with no inbox in the account' do
    importar([{ 'nome' => 'SLA - WhatsApp', 'canais' => ['Channel::Whatsapp'], 'alvos' => { 'default' => { 'first_response' => 5 } } }])
    conversation = create(:conversation, account: account, inbox: chat)

    expect(Staydesk::Sla::PolicyMatcher.new(conversation).perform).to be_nil
  end
end

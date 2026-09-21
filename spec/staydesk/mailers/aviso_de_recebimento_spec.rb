require 'rails_helper'

# O aviso de recebimento é o primeiro e-mail que o cliente recebe: precisa dizer
# o número do chamado, o que ele pediu, por onde entrou e como acompanhar.
RSpec.describe 'aviso de recebimento' do
  let(:account) { create(:account, name: 'StayCloud', locale: 'pt_BR') }
  let(:channel) { create(:channel_email, account: account, email: 'support@staycloud.com.br') }
  let(:inbox) { channel.inbox }
  let(:conversation) do
    create(:conversation, account: account, inbox: inbox,
                          additional_attributes: { 'mail_subject' => 'Site fora do ar' })
  end

  before do
    ENV['FRONTEND_URL'] = 'https://staydesk-staging.staycloud.com.br'
    Staydesk::ConfigImportService.new(
      account: account,
      config: { 'conta' => { 'painel_do_cliente' => 'https://beta.staycloud.com/dashboard/suporte/meus' } }
    ).perform
  end

  def aviso
    regra = AutomationRule.create!(
      account: account, name: 'Confirmação de recebimento', event_name: 'conversation_created',
      conditions: [{ 'attribute_key' => 'status', 'filter_operator' => 'equal_to', 'values' => ['open'] }],
      actions: [{ 'action_name' => 'staydesk_aviso_de_recebimento',
                  'action_params' => ['Olá! O seu ticket #{{conversation.display_id}} já foi recebido.'] }]
    )
    AutomationRules::ActionService.new(regra, account, conversation).perform
    conversation.messages.reload.last
  end

  it 'accepts the StayDesk action on a rule' do
    expect { aviso }.to change { conversation.messages.count }.by(1)
  end

  it 'marks the message so the e-mail can present it as a receipt' do
    expect(aviso.content_attributes['staydesk_aviso']).to eq('recebimento')
  end

  it 'shows the ticket details and the portal button in the e-mail' do
    mensagem = aviso
    corpo = described_class.to_s && ConversationReplyMailer.email_reply(mensagem).body.encoded

    expect(corpo).to include("##{conversation.display_id}")
    expect(corpo).to include('Site fora do ar')
    expect(corpo).to include('Dados do chamado')
    expect(corpo).to include('https://beta.staycloud.com/dashboard/suporte/meus')
    expect(corpo).to include('Acompanhar no painel')
  end

  it 'leaves out the button when the account has no portal' do
    account.update!(custom_attributes: {})
    corpo = ConversationReplyMailer.email_reply(aviso).body.encoded

    expect(corpo).to include('Dados do chamado')
    expect(corpo).not_to include('Acompanhar no painel')
  end
end

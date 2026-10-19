require 'rails_helper'

# O assunto que o dashboard recebe pela API no formato do Zendesk.
RSpec.describe Staydesk::Zendesk::Serializer do
  let(:account) { create(:account, locale: 'pt_BR') }
  let(:email) { create(:inbox, account: account, channel: create(:channel_email, account: account)) }
  let(:chat) { create(:inbox, account: account, channel: create(:channel_widget, account: account)) }
  let(:contato) { create(:contact, account: account, name: 'Luiz Gustavo') }

  def assunto(conversa)
    described_class.new(account).send(:assunto, conversa)
  end

  it 'uses the e-mail subject for a ticket' do
    conversa = create(:conversation, account: account, inbox: email, contact: contato, additional_attributes: { 'mail_subject' => 'Site fora do ar' })

    expect(assunto(conversa)).to eq('Site fora do ar')
  end

  it 'calls a chat "Chat com <cliente>" instead of using the first message' do
    conversa = create(:conversation, account: account, inbox: chat, contact: contato)
    create(:message, conversation: conversa, account: account, inbox: chat, message_type: :incoming, content: 'oi, meu site caiu')

    expect(assunto(conversa)).to eq('Chat com Luiz Gustavo')
  end
end

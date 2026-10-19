require 'rails_helper'

# Regra por assunto vale para e-mail e para o ticket que chega pela API.
RSpec.describe Conversation do
  let(:account) { create(:account) }
  let(:api) { create(:inbox, account: account, channel: create(:channel_api, account: account)) }

  it 'copies the API ticket subject to mail_subject' do
    conversa = create(:conversation, account: account, inbox: api, custom_attributes: { 'assunto' => 'Migração do site' })

    expect(conversa.additional_attributes['mail_subject']).to eq('Migração do site')
  end

  it 'keeps an e-mail subject that is already there' do
    conversa = create(:conversation, account: account, inbox: api, custom_attributes: { 'assunto' => 'Outro' },
                                     additional_attributes: { 'mail_subject' => 'Assunto do e-mail' })

    expect(conversa.additional_attributes['mail_subject']).to eq('Assunto do e-mail')
  end
end

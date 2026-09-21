require 'rails_helper'

# A resposta que chega ao cliente é a cara da empresa: precisa sair com a marca,
# com quem respondeu e, quando for o pedido de avaliação, com um convite claro
# em vez de um link solto.
RSpec.describe ConversationReplyMailer do
  let(:account) { create(:account, name: 'StayCloud', locale: 'pt_BR') }
  let(:agent) { create(:user, account: account, role: :agent, name: 'Matheus Fonseca') }
  let(:channel) { create(:channel_email, account: account, email: 'support@staycloud.com.br') }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }

  before { ENV['FRONTEND_URL'] = 'https://staydesk-staging.staycloud.com.br' }

  def corpo(mail)
    mail.body.encoded
  end

  it 'wraps the reply in the brand layout, with the logo and who answered' do
    message = create(:message, account: account, inbox: inbox, conversation: conversation,
                               message_type: :outgoing, sender: agent, content: 'Resolvido, qualquer coisa é só chamar.')

    mail = described_class.email_reply(message)

    expect(corpo(mail)).to include('/brand-assets/logo-email.png')
    expect(corpo(mail)).to include(agent.available_name)
    expect(corpo(mail)).to include('StayCloud')
    expect(corpo(mail)).to include('support@staycloud.com.br')
    expect(corpo(mail)).to include('Resolvido, qualquer coisa é só chamar.')
  end

  it 'invites the customer to rate instead of pasting a bare link' do
    message = conversation.messages.create!(account: account, inbox: inbox, message_type: :template,
                                            content_type: :input_csat, content: 'Avalie o atendimento')

    mail = described_class.email_reply(message)

    expect(corpo(mail)).to include('Como foi o nosso atendimento?')
    expect(corpo(mail)).to include('Avaliar atendimento')
    expect(corpo(mail)).to include("#{conversation.csat_survey_link}?rating=5")
  end

  it 'says the agent is from the company in Portuguese' do
    inbox.update!(sender_name_type: :friendly) if inbox.respond_to?(:sender_name_type)
    message = create(:message, account: account, inbox: inbox, conversation: conversation,
                               message_type: :outgoing, sender: agent, content: 'Oi')

    mail = described_class.email_reply(message)

    expect(mail[:from].to_s).not_to include(' de StayCloud')
  end
end

# O assunto de uma conversa, como no Zendesk: ticket (e-mail e API) tem o assunto
# do chamado; chat e WhatsApp viram "Chat com <cliente>". Uma regra só, usada na
# API da conversa (bloco `staydesk`), na API compatível com o Zendesk e na tela.
class Staydesk::ConversationSubject
  CANAIS_DE_TICKET = %w[Channel::Email Channel::Api].freeze

  def initialize(conversation)
    @conversa = conversation
  end

  def to_s
    I18n.with_locale(@conversa.account&.locale.presence || I18n.default_locale) do
      next do_ticket if ticket?

      I18n.t('staydesk.subject.chat_with', name: @conversa.contact&.name.presence || I18n.t('staydesk.subject.unknown_contact'))
    end
  end

  def ticket?
    CANAIS_DE_TICKET.include?(@conversa.inbox&.channel_type)
  end

  private

  def do_ticket
    @conversa.additional_attributes.to_h['mail_subject'].presence || @conversa.custom_attributes.to_h['assunto'].presence ||
      @conversa.additional_attributes.to_h['assunto'].presence || I18n.t('staydesk.subject.none')
  end
end

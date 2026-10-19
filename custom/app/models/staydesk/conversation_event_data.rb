# Eventos em tempo real e webhooks da conversa levam o mesmo bloco `staydesk` da
# API (assunto, status do ticket, campos que faltam): o front não recalcula.
# Entra em Conversation pelo Custom::Conversation.
module Staydesk::ConversationEventData
  def push_event_data
    super.merge(staydesk: Staydesk::ConversationPayload.new(self).to_h)
  end

  def webhook_data
    super.merge(staydesk: Staydesk::ConversationPayload.new(self).to_h)
  end
end

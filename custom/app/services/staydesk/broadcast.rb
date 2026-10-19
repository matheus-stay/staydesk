# Eventos do StayDesk em tempo real, no mesmo canal que o produto já usa: o
# `pubsub_token` do agente, assinado pelo front no RoomChannel. Formato igual ao
# do produto: { event:, data: }. Assim um front não precisa ficar perguntando se
# chegou convite ou se o status mudou.
#
#   staydesk.offer.created / .accepted / .declined / .expired — convite de atendimento
#   staydesk.agent_status.changed — status do agente trocado (por ele, pelo tempo
#                                   limite, pela aba fechada ou pela regra de convites perdidos)
module Staydesk::Broadcast
  module_function

  def para(user, evento, dados)
    return if user&.pubsub_token.blank?

    ActionCable.server.broadcast(user.pubsub_token, { event: evento, data: dados })
  end

  def convite(convite, evento)
    conversa = convite.conversation
    para(convite.user, "staydesk.offer.#{evento}", {
           id: convite.id, status: convite.status, seconds_left: convite.segundos_restantes,
           expires_at: convite.expires_at&.to_i, conversation_id: conversa.display_id,
           contact_name: conversa.contact&.name, inbox_name: conversa.inbox&.name,
           channel_type: conversa.inbox&.channel_type, subject: Staydesk::ConversationSubject.new(conversa).to_s
         })
  end

  def status_do_agente(account_user, status)
    para(account_user.user, 'staydesk.agent_status.changed', {
           account_id: account_user.account_id, current_status_id: status&.id, name: status&.name,
           availability: account_user.reload.availability
         })
  end
end

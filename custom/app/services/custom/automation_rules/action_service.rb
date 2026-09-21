# Entra em AutomationRules::ActionService pelo gancho prepend_mod_with.
#
# Aviso de recebimento: a confirmação que o cliente recebe quando o chamado
# entra. É uma mensagem normal na conversa, mas marcada, para o e-mail
# apresentá-la como o cartão do chamado (número, assunto, canal, data e o botão
# do painel) em vez de uma linha solta.
module Custom::AutomationRules::ActionService
  MARCA = 'recebimento'.freeze

  # A marca vai junto na criação, não depois: o e-mail sai no gancho de mensagem
  # criada e precisa já encontrá-la. O texto passa pelas variáveis do produto no
  # próprio modelo, então `{{conversation.display_id}}` vira o número do ticket.
  def staydesk_aviso_de_recebimento(message)
    return if conversation_a_tweet?

    @conversation.messages.create!(
      account_id: @conversation.account_id,
      inbox_id: @conversation.inbox_id,
      message_type: :outgoing,
      content: message[0],
      private: false,
      content_attributes: { automation_rule_id: @rule.id, staydesk_aviso: MARCA }
    )
  end
end

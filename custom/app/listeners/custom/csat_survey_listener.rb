# Entra em CsatSurveyListener pelo gancho prepend_mod_with.
#
# O produto pede a avaliação no mesmo instante em que a conversa é resolvida. No
# e-mail isso chega fora de ordem: a resposta que resolveu ainda está a caminho
# e a pesquisa passa na frente. Aqui a pesquisa espera; quanto ela espera é
# configuração do canal, como no Zendesk.
module Custom::CsatSurveyListener
  ATRASO_PADRAO_EM_MINUTOS = 5

  def conversation_status_changed(event)
    conversation = extract_conversation_and_account(event)[0]
    return unless conversation.resolved?

    Staydesk::Csat::SurveyJob.set(wait: Staydesk::Csat.atraso(conversation.inbox)).perform_later(conversation.id)
  end
end

# A pesquisa de satisfação sai um tempo depois de a conversa ser resolvida, não
# no mesmo instante: a resposta que resolveu o chamado ainda está saindo, e no
# e-mail as duas chegavam fora de ordem, com a pesquisa antes da resposta.
class Staydesk::Csat::SurveyJob < ApplicationJob
  queue_as :low

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank? || !conversation.resolved?

    CsatSurveyService.new(conversation: conversation).perform
  end
end

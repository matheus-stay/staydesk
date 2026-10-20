# A conversa e a fila com aceite: o convite que a distribuição guarda e a volta
# para a fila quando o cliente reabre. Entra em Conversation pelo
# Custom::Conversation; separado para o módulo da camada não virar uma classe só.
module Staydesk::ConversationQueue
  def self.included(base)
    base.attr_accessor :staydesk_convidar, :staydesk_reaberta_pelo_cliente
  end

  # Fila com aceite (SPEC-16): a distribuição guarda em `staydesk_convidar` o
  # agente escolhido em vez de atribuir; aqui o convite é criado, já com a
  # conversa gravada. Atribuição manual não passa por convite.
  def staydesk_lancar_convite!
    agente = staydesk_convidar
    return if agente.blank? || !persisted?

    self.staydesk_convidar = nil
    Staydesk::OfferService.new(self).offer!(agente)
  end

  private

  # Como no Zendesk: chat encerrado que o cliente reabre volta para a fila, sem
  # o agente anterior, e é oferecido de novo. Vale para o canal de trabalho
  # marcado com `reopen_to_queue` (chat); ticket reaberto fica com quem atendia.
  # Roda antes do resto: com o responsável já tirado, o status do ticket volta
  # para o inicial em vez de "em andamento".
  def staydesk_reabrir_na_fila(mudancas)
    reaberta = staydesk_reaberta_pelo_cliente
    self.staydesk_reaberta_pelo_cliente = nil
    return unless reaberta && mudancas['status']&.last == 'open' && assignee_id.present?
    return unless Staydesk::LoadQueue.for_inbox(inbox)&.reopen_to_queue

    update!(assignee_id: nil)
    Staydesk::Queues::SweepJob.perform_later(account_id)
  end
end

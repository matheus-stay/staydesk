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

  # A conversa nova passa pelas filas antes de a distribuição escolher o agente
  # (SPEC-15). Roda no mesmo processo do commit, não em job, para chegar antes.
  # Fila que decide pelo assunto só define o grupo aqui, depois de gravar: a
  # distribuição roda logo em seguida, para o convite sair na hora e não na
  # próxima varredura. Se a conversa já nasceu com responsável, o status do
  # ticket acompanha.
  def staydesk_route_to_queue
    fila = Staydesk::QueueRouter.new(self).perform
    Staydesk::TicketStatusService.new(self).follow_assignment! if assignee_id.present?
    staydesk_redistribuir! if fila
  end

  # Como no Zendesk, vaga liberada é preenchida na hora: resolveu, pausou ou a
  # conversa ficou sem responsável, a fila anda sem esperar a varredura.
  def staydesk_liberou_vaga(mudancas)
    antes, depois = mudancas['status']
    saiu_de_aberta = antes == 'open' && depois.present? && depois != 'open'
    ficou_sem_responsavel = mudancas.key?('assignee_id') && assignee_id.blank?
    staydesk_redistribuir! if saiu_de_aberta || ficou_sem_responsavel
  end

  def staydesk_redistribuir!
    Staydesk::Queues::SweepJob.perform_later(account_id)
  end

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
  end
end

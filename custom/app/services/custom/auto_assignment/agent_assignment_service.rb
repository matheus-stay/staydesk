# Entra em AutoAssignment::AgentAssignmentService pelo gancho prepend_mod_with.
# Fila com aceite (SPEC-16): a distribuição escolhe o agente do mesmo jeito
# (rodízio entre quem está online, na lista e com vaga), mas em vez de atribuir,
# convida. A conversa fica sem responsável até ele aceitar, e o convite pendente
# reserva a vaga dele enquanto isso (Staydesk::AgentLoadService).
module Custom::AutoAssignment::AgentAssignmentService
  def find_assignee
    # Conversa com convite pendente já está com alguém decidindo.
    return nil if conversation.persisted? && Staydesk::Offer.pendentes.exists?(conversation_id: conversation.id)
    return nil if staydesk_aguardando_fila?

    agente = super
    return agente if agente.blank? || !staydesk_fila_com_aceite?

    conversation.staydesk_convidar = agente
    nil
  end

  # No caminho `perform` a conversa não é salva quando ninguém é atribuído, então
  # o convite guardado em `find_assignee` é lançado aqui; nos caminhos que salvam
  # a conversa, os ganchos dela lançam.
  def perform
    super
    conversation.staydesk_lancar_convite!
  end

  private

  # Sem grupo ainda, mas com fila para este canal: é a fila que decide pelo
  # assunto, depois de gravar (QueueRouter). Atribuir agora entregava o ticket
  # direto, sem convite e fora da fila; a distribuição roda de novo assim que o
  # grupo é definido.
  def staydesk_aguardando_fila?
    return false if conversation.team_id.present?

    Staydesk::Queue.active.where(account_id: conversation.account_id).any? { |fila| fila.atende_canal?(conversation.inbox) }
  end

  def staydesk_fila_com_aceite?
    Staydesk::Queue.da_conversa(conversation)&.accept_required || false
  end
end

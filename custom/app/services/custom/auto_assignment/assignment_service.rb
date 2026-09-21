# Entra em AutoAssignment::AssignmentService pelo gancho prepend_mod_with: a
# distribuição nova também respeita o transbordo da fila, sem trocar o grupo da
# conversa (SPEC-15).
module Custom::AutoAssignment::AssignmentService
  # Fila com aceite: convida em vez de atribuir (SPEC-16). O convite pendente
  # reserva a vaga do agente; a conversa segue sem responsável até o aceite.
  def assign_conversation(conversation, agent)
    fila = Staydesk::Queue.da_conversa(conversation)
    return super unless fila&.accept_required
    return false if Staydesk::Offer.pendentes.exists?(conversation_id: conversation.id)

    Staydesk::OfferService.new(conversation).offer!(agent).present?
  end

  def filter_agents_by_team(agents, conversation)
    return super if conversation&.team_id.blank?

    time = conversation.team
    return nil if time.blank? || time.allow_auto_assign.blank?

    ids = Staydesk::QueueOverflow.new(conversation).eligible_user_ids(agents.map(&:user_id))
    agents.where(user_id: ids)
  end
end

# Oferece a conversa ao agente e cuida do aceite, da recusa e do tempo (SPEC-16).
class Staydesk::OfferService
  def initialize(conversation)
    @conversation = conversation
  end

  # Cria o convite quando a fila da conversa exige aceite.
  def offer!(user)
    fila = fila_da_conversa
    return if fila.blank? || !fila.accept_required || user.blank?

    Staydesk::Offer.pendentes.where(conversation: @conversation).update_all(status: 'expirada', answered_at: Time.current)
    convite = Staydesk::Offer.create!(
      account_id: @conversation.account_id, conversation: @conversation, user: user,
      expires_at: fila.accept_timeout_seconds.seconds.from_now
    )
    Staydesk::Offers::ExpireJob.set(wait: fila.accept_timeout_seconds.seconds + 2.seconds).perform_later(convite.id)
    convite
  end

  # Aceitou: agora sim o caso entra em andamento (o convite segurou isso na atribuição).
  def accept!(convite)
    convite.update!(status: 'aceita', answered_at: Time.current)
    if Staydesk::TicketStatus.active.exists?(account_id: @conversation.account_id, apply_on_assign: true)
      Staydesk::TicketStatusService.new(@conversation).follow_assignment!
    end
    convite
  end

  # Recusa e expiração devolvem a conversa para a fila, sem o agente que não pegou.
  def decline!(convite, status: 'recusada')
    convite.update!(status: status, answered_at: Time.current)
    return convite unless @conversation.assignee_id == convite.user_id

    @conversation.update!(assignee: nil)
    redistribuir(sem: convite.user_id)
    convite
  end

  private

  def fila_da_conversa
    Staydesk::Queue.da_equipe(@conversation.account_id, @conversation.team_id)
  end

  def redistribuir(sem:)
    permitidos = Staydesk::QueueOverflow.new(@conversation)
                                        .eligible_user_ids(@conversation.inbox.member_ids_with_assignment_capacity) - [sem]
    return if permitidos.blank?

    AutoAssignment::AgentAssignmentService.new(conversation: @conversation, allowed_agent_ids: permitidos).perform
  end
end

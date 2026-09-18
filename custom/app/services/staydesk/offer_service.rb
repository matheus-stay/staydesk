# Oferece a conversa ao agente e cuida do aceite, da recusa e do tempo (SPEC-16).
# A conversa só passa a ser do agente no aceite; até lá fica sem responsável, com
# o convite pendente reservando a vaga dele.
class Staydesk::OfferService
  def initialize(conversation)
    @conversation = conversation
  end

  # Cria o convite quando a fila da conversa exige aceite.
  def offer!(user)
    fila = fila_da_conversa
    return if fila.blank? || !fila.accept_required || user.blank?

    Staydesk::Offer.pendentes.where(conversation: @conversation).find_each { |antigo| antigo.update!(status: 'expirada', answered_at: Time.current) }
    convite = Staydesk::Offer.create!(
      account_id: @conversation.account_id, conversation: @conversation, user: user,
      expires_at: fila.accept_timeout_seconds.seconds.from_now
    )
    Staydesk::Offers::ExpireJob.set(wait: fila.accept_timeout_seconds.seconds + 2.seconds).perform_later(convite.id)
    convite
  end

  # Aceitou: agora a conversa é dele (e o status acompanha, pelos ganchos da
  # conversa). Se alguém já pegou por outro caminho, o convite morre.
  def accept!(convite)
    @conversation.reload
    if @conversation.assignee_id.present? && @conversation.assignee_id != convite.user_id
      convite.update!(status: 'expirada', answered_at: Time.current)
      return convite
    end

    convite.update!(status: 'aceita', answered_at: Time.current)
    @conversation.update!(assignee: convite.user) if @conversation.assignee_id != convite.user_id
    convite
  end

  # Recusa e expiração devolvem a conversa para a fila, sem o agente que não
  # pegou. Sem mais ninguém para receber, a regra da fila decide: oferece de
  # novo ao mesmo agente (na hora ou depois da espera) ou deixa na fila.
  def decline!(convite, status: 'recusada')
    convite.update!(status: status, answered_at: Time.current)
    @conversation.update!(assignee: nil) if @conversation.assignee_id == convite.user_id

    # Perdeu convites demais seguidos? Sai do status antes de a fila voltar para ele.
    Staydesk::MissedOffersService.new(@conversation.account, convite.user_id).verificar!
    redistribuir(sem: convite.user_id)
    reoferecer_ao_mesmo unless oferecida_ou_atribuida?
    convite
  end

  private

  def fila_da_conversa
    Staydesk::Queue.da_equipe(@conversation.account_id, @conversation.team_id)
  end

  def reoferecer_ao_mesmo
    fila = fila_da_conversa
    return if fila.blank? || !fila.reoffer_same_agent
    return redistribuir(sem: nil) if fila.reoffer_after_seconds.zero?

    # A varredura pega a conversa de novo, já sem convite pendente.
    Staydesk::Queues::SweepJob.set(wait: fila.reoffer_after_seconds.seconds).perform_later(@conversation.account_id)
  end

  def oferecida_ou_atribuida?
    Staydesk::Offer.pendentes.exists?(conversation_id: @conversation.id) || @conversation.reload.assignee_id.present?
  end

  def redistribuir(sem:)
    permitidos = Staydesk::QueueOverflow.new(@conversation)
                                        .eligible_user_ids(@conversation.inbox.member_ids_with_assignment_capacity) - [sem].compact
    return if permitidos.blank?

    AutoAssignment::AgentAssignmentService.new(conversation: @conversation, allowed_agent_ids: permitidos).perform
  end
end

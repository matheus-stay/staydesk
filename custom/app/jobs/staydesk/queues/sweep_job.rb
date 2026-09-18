# Varre a fila e entrega o que está parado. O Chatwoot só distribui quando a
# conversa nasce ou recebe mensagem: quem chegou antes de o agente ficar
# disponível ficaria esperando para sempre. Aqui a fila é oferecida de novo a
# cada minuto e assim que alguém muda de status, mais velha primeiro.
#
# Quem pode pegar sai de Staydesk::QueueOverflow (grupo dono, transbordo e a
# espera configurada) cruzado com a carga do status do agente, então o mesmo
# job serve ao transbordo por tempo.
class Staydesk::Queues::SweepJob < ApplicationJob
  queue_as :scheduled_jobs

  LIMITE = 200

  # Sem conta, varre todas (cron). Com conta, varre só a dela (troca de status).
  def perform(account_id = nil)
    esperando(account_id).each { |conversa| distribuir(conversa) }
  end

  private

  def esperando(account_id)
    escopo = Conversation.where(assignee_id: nil, status: :open)
    escopo = escopo.where(account_id: account_id) if account_id.present?
    escopo.order(:created_at).limit(LIMITE)
  end

  def distribuir(conversa)
    return unless conversa.inbox.enable_auto_assignment?

    # Sem grupo dono não há fila: conversa que entrou antes de a fila existir, ou
    # que nenhuma regra pegou na criação, passa pelo roteador agora.
    Staydesk::QueueRouter.new(conversa).perform if conversa.team_id.blank?
    return if conversa.reload.team_id.blank?

    permitidos = Staydesk::QueueOverflow.new(conversa).eligible_user_ids(conversa.inbox.member_ids_with_assignment_capacity)
    return if permitidos.blank?

    AutoAssignment::AgentAssignmentService.new(conversation: conversa, allowed_agent_ids: permitidos).perform
  end
end

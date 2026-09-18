# Varre a fila e entrega o que está parado. O Chatwoot só distribui quando a
# conversa nasce ou recebe mensagem: quem chegou antes de o agente ficar
# disponível ficaria esperando para sempre. Aqui a fila é oferecida de novo a
# cada minuto e assim que alguém muda de status, mais velha primeiro.
#
# Quem pode pegar sai de Staydesk::QueueOverflow (grupos principais, secundários
# e a espera configurada) cruzado com a carga do status do agente, então o mesmo
# job serve ao transbordo por tempo.
class Staydesk::Queues::SweepJob < ApplicationJob
  queue_as :scheduled_jobs

  LIMITE = 200

  # Sem conta, varre todas (cron). Com conta, varre só a dela (troca de status).
  def perform(account_id = nil)
    ordenar(esperando(account_id)).each { |conversa| distribuir(conversa) }
  end

  private

  def esperando(account_id)
    escopo = Conversation.where(assignee_id: nil, status: :open)
    escopo = escopo.where(account_id: account_id) if account_id.present?
    escopo.order(:created_at).limit(LIMITE).to_a
  end

  # A ordem de entrega é da fila: primeiro a fila de cima, e dentro dela o modo
  # dela. No modo `sla`, quem está mais perto de vencer sai primeiro, e o que
  # não tem SLA vai depois, por chegada. Sem fila, vale a chegada.
  def ordenar(conversas)
    filas = filas_por_time(conversas)
    prazos = prazos_por_conversa(conversas)
    conversas.sort_by do |conversa|
      fila = filas[[conversa.account_id, conversa.team_id]]
      posicao = fila&.position || Float::INFINITY
      prazo = fila&.priority_mode == 'sla' ? prazos[conversa.id] : nil
      [posicao, prazo.nil? ? 1 : 0, prazo || conversa.created_at]
    end
  end

  # A fila de cada grupo: a primeira em que ele é principal e, faltando, a
  # primeira em que ele é secundário (mesma regra de Staydesk::Queue.da_equipe).
  def filas_por_time(conversas)
    filas = Staydesk::Queue.active.where(account_id: conversas.map(&:account_id).uniq).ordered.to_a
    pares = pares_por_grupo(filas, :team_ids) + pares_por_grupo(filas, :fallback_team_ids)
    pares.each_with_object({}) { |(chave, fila), mapa| mapa[chave] ||= fila }
  end

  def pares_por_grupo(filas, campo)
    filas.flat_map { |fila| fila.public_send(campo).map { |time| [[fila.account_id, time], fila] } }
  end

  # O prazo mais próximo entre as métricas ainda abertas do SLA da conversa.
  def prazos_por_conversa(conversas)
    Staydesk::AppliedSla.where(conversation_id: conversas.map(&:id), status: 'running').each_with_object({}) do |sla, mapa|
      abertos = [
        (sla.first_response_due_at unless sla.first_response_met_at),
        (sla.next_response_due_at unless sla.next_response_met_at),
        (sla.resolution_due_at unless sla.resolution_met_at)
      ].compact
      mapa[sla.conversation_id] = abertos.min if abertos.any?
    end
  end

  def distribuir(conversa)
    return unless conversa.inbox.enable_auto_assignment?

    # Sem grupo não há fila: conversa que entrou antes de a fila existir, ou
    # que nenhuma regra pegou na criação, passa pelo roteador agora.
    Staydesk::QueueRouter.new(conversa).perform if conversa.team_id.blank?
    return if conversa.reload.team_id.blank?

    permitidos = Staydesk::QueueOverflow.new(conversa).eligible_user_ids(conversa.inbox.member_ids_with_assignment_capacity)
    return if permitidos.blank?

    AutoAssignment::AgentAssignmentService.new(conversation: conversa, allowed_agent_ids: permitidos).perform
  end
end

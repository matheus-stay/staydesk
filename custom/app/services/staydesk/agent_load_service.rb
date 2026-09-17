# Carga de atendimento simultâneo por fila (SPEC-11).
#
# O Chatwoot community não tem limite de conversas por agente: a distribuição
# automática entrega enquanto houver agente online. Aqui o limite vem do status
# do agente, separado por fila: conversas de caixas de e-mail contam como
# ticket, as demais como chat. Conta só o que está de fato em atendimento
# (status base aberto), então o que está esperando o cliente libera vaga.
class Staydesk::AgentLoadService
  QUEUES = Staydesk::AgentStatus::QUEUES
  TICKET_CHANNELS = ['Channel::Email'].freeze

  def self.queue_for(inbox)
    TICKET_CHANNELS.include?(inbox.channel_type) ? 'ticket' : 'chat'
  end

  def initialize(account)
    @account = account
  end

  # Dos ids recebidos, quem ainda cabe mais uma conversa desta caixa.
  def with_capacity(inbox, user_ids)
    user_ids - over_capacity(inbox, user_ids)
  end

  # Quem já bateu o limite do próprio status para a fila desta caixa.
  def over_capacity(inbox, user_ids)
    return [] if user_ids.blank?

    queue = self.class.queue_for(inbox)
    limits = capacity_by_user(queue, user_ids)
    return [] if limits.empty?

    loads = load_by_user(queue, limits.keys)
    limits.filter_map { |user_id, limit| user_id if loads.fetch(user_id, 0) >= limit }
  end

  # Conversas em atendimento agora, por agente, nas caixas daquela fila.
  def load_by_user(queue, user_ids)
    return {} if user_ids.blank?

    @account.conversations.open
            .where(assignee_id: user_ids, inbox_id: inbox_ids_for(queue))
            .group(:assignee_id).count
  end

  # Painel de carga: status atual, carga e limite de cada agente, nas duas filas.
  def summary(user_ids)
    statuses = statuses_by_user(user_ids)
    loads = QUEUES.index_with { |queue| load_by_user(queue, user_ids) }

    user_ids.index_with do |user_id|
      status = statuses[user_id]
      {
        status: status,
        load: QUEUES.index_with { |queue| loads[queue].fetch(user_id, 0) },
        capacity: QUEUES.index_with { |queue| status&.capacity_for(queue) }
      }
    end
  end

  private

  def capacity_by_user(queue, user_ids)
    statuses_by_user(user_ids).filter_map do |user_id, status|
      limit = status&.capacity_for(queue)
      [user_id, limit] if limit
    end.to_h
  end

  def statuses_by_user(user_ids)
    return {} if user_ids.blank?

    rows = Staydesk::AgentStatusPeriod.current
                                      .joins(:account_user)
                                      .where(account_users: { account_id: @account.id, user_id: user_ids })
                                      .preload(:agent_status)
                                      .select('staydesk_agent_status_periods.*, account_users.user_id AS staydesk_user_id')
    rows.to_h { |row| [row.staydesk_user_id, row.agent_status] }
  end

  def inbox_ids_for(queue)
    @inbox_ids_for ||= {}
    @inbox_ids_for[queue] ||= begin
      scope = @account.inboxes
      scope = queue == 'ticket' ? scope.where(channel_type: TICKET_CHANNELS) : scope.where.not(channel_type: TICKET_CHANNELS)
      scope.pluck(:id)
    end
  end
end

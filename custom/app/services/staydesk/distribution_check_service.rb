# Por que este agente recebe, ou não recebe, cada fila. Responde à pergunta
# "coloquei online e não caiu nada" sem precisar abrir o console: para cada
# agente, cada condição da distribuição com sim ou não, e o motivo em palavras.
class Staydesk::DistributionCheckService
  def initialize(account)
    @account = account
  end

  def perform
    @account.account_users.includes(:user).map { |vinculo| linha(vinculo) }
  end

  private

  def conectados
    @conectados ||= (OnlineStatusTracker.get_available_users(@account.id) || {})
                    .select { |_id, estado| estado == 'online' }.keys.map(&:to_i)
  end

  def filas
    @filas ||= Staydesk::Queue.active.where(account_id: @account.id).ordered.includes(:team)
  end

  def linha(vinculo)
    usuario = vinculo.user
    status = Staydesk::AgentStatusService.new(vinculo).current
    times = usuario.teams.where(account_id: @account.id).ids
    caixas = usuario.inboxes.where(account_id: @account.id).ids
    {
      user_id: usuario.id, name: usuario.name,
      online: conectados.include?(usuario.id),
      status: status&.name, availability: vinculo.availability,
      queues: filas.map { |fila| por_fila(fila, status, times, caixas, usuario) }
    }
  end

  # Cada condição da roda, na ordem em que a distribuição as aplica. O agente é
  # um hash com o que já foi lido dele, para não reler por fila.
  def por_fila(fila, status, times, caixas, usuario)
    caixas_da_fila = caixas_que_a_fila_pega(fila)
    carga = Staydesk::LoadQueue.for_inbox(caixas_da_fila.first)&.key if caixas_da_fila.any?
    limite = status&.capacity_for(carga) if carga
    agente = { status: status, times: times, caixas: caixas, id: usuario.id, limite: limite }
    checks = checks_de(fila, caixas_da_fila, agente)
    { queue_id: fila.id, queue: fila.name, team: fila.team.name, load_queue: carga,
      capacity: limite, checks: checks, receives: checks.values.all? }
  end

  def checks_de(fila, caixas_da_fila, agente)
    status = agente[:status]
    {
      connected: conectados.include?(agente[:id]),
      available: status.present? && status.availability == 'online',
      has_capacity: agente[:limite].nil? ? status.present? : agente[:limite].positive?,
      in_group: (fila.team_ids + fila.fallback_team_ids).intersect?(agente[:times]),
      inbox_member: caixas_da_fila.map(&:id).intersect?(agente[:caixas])
    }
  end

  # As caixas que a fila pega, pelo canal e pela caixa, uma vez por fila.
  def caixas_que_a_fila_pega(fila)
    @caixas_por_fila ||= {}
    @caixas_por_fila[fila.id] ||= @account.inboxes.to_a.select { |caixa| fila.atende_canal?(caixa) }
  end
end

# Tempo de cada agente em cada status dentro da janela pedida. Períodos abertos
# contam até agora; períodos que começaram antes da janela entram só pelo pedaço
# que cai dentro dela, senão o dia de ontem apareceria no relatório de hoje.
class Staydesk::Kpi::AgentTimeService
  def initialize(account:, since:, ate:)
    @account = account
    @since = since
    @ate = ate
  end

  def perform
    @account.account_users.includes(:user).map { |vinculo| linha(vinculo) }
  end

  private

  def linha(vinculo)
    periodos_do_agente = periodos(vinculo).to_a
    por_status = tempo_por_status(periodos_do_agente)
    atual = Staydesk::AgentStatusService.new(vinculo).current
    online = segundos_online(periodos_do_agente)
    dias = dias_com_tempo_online(periodos_do_agente)
    {
      user_id: vinculo.user_id,
      nome: vinculo.user.name,
      email: vinculo.user.email,
      status_atual: atual&.name,
      disponibilidade: vinculo.availability,
      segundos_por_status: por_status,
      segundos_disponivel: online,
      segundos_online: online,
      dias_online: dias,
      media_diaria_online_segundos: dias.zero? ? 0 : (online / dias),
      segundos_no_periodo: por_status.values.sum
    }
  end

  def periodos(vinculo)
    Staydesk::AgentStatusPeriod.includes(:agent_status)
                               .where(account_user_id: vinculo.id)
                               .where(started_at: ...@ate)
                               .where('ended_at IS NULL OR ended_at > ?', @since)
  end

  def tempo_por_status(periodos_do_agente)
    periodos_do_agente.each_with_object(Hash.new(0)) do |periodo, soma|
      nome = periodo.agent_status&.name
      next if nome.blank?

      soma[nome] += duracao(periodo)
    end
  end

  # Só conta o tempo nos status marcados como "contabiliza tempo online".
  def segundos_online(periodos_do_agente)
    periodos_do_agente.sum { |periodo| periodo.agent_status&.counts_as_online ? duracao(periodo) : 0 }
  end

  # Em quantos dias distintos houve tempo online: é o divisor da média diária.
  def dias_com_tempo_online(periodos_do_agente)
    periodos_do_agente.select { |periodo| periodo.agent_status&.counts_as_online && duracao(periodo).positive? }
                      .flat_map { |periodo| dias_do_periodo(periodo) }.uniq.size
  end

  def dias_do_periodo(periodo)
    inicio = [periodo.started_at, @since].max.to_date
    fim = [periodo.ended_at || Time.current, @ate].min.to_date
    (inicio..fim).to_a
  end

  def duracao(periodo)
    inicio = [periodo.started_at, @since].max
    fim = [periodo.ended_at || Time.current, @ate].min
    fim > inicio ? (fim - inicio).round : 0
  end
end

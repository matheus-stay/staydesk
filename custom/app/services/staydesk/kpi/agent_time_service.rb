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
    por_status = tempo_por_status(vinculo)
    atual = Staydesk::AgentStatusService.new(vinculo).current
    {
      user_id: vinculo.user_id,
      nome: vinculo.user.name,
      email: vinculo.user.email,
      status_atual: atual&.name,
      disponibilidade: vinculo.availability,
      segundos_por_status: por_status,
      segundos_disponivel: segundos_disponivel(por_status),
      segundos_no_periodo: por_status.values.sum
    }
  end

  def periodos(vinculo)
    Staydesk::AgentStatusPeriod.includes(:agent_status)
                               .where(account_user_id: vinculo.id)
                               .where(started_at: ...@ate)
                               .where('ended_at IS NULL OR ended_at > ?', @since)
  end

  def tempo_por_status(vinculo)
    periodos(vinculo).each_with_object(Hash.new(0)) do |periodo, soma|
      nome = periodo.agent_status&.name
      next if nome.blank?

      soma[nome] += duracao(periodo)
    end
  end

  def duracao(periodo)
    inicio = [periodo.started_at, @since].max
    fim = [periodo.ended_at || Time.current, @ate].min
    fim > inicio ? (fim - inicio).round : 0
  end

  # "Disponível" é o que o status do agente diz: online atende, ausente não.
  def segundos_disponivel(por_status)
    online = Staydesk::AgentStatus.where(account_id: @account.id, availability: 'online').pluck(:name)
    por_status.slice(*online).values.sum
  end
end

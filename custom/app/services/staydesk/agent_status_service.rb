# Troca o status de um agente: fecha o período aberto, abre o novo e alinha a
# disponibilidade do Chatwoot (online para status disponível, ocupado para ausente).
class Staydesk::AgentStatusService
  def initialize(account_user)
    @account_user = account_user
  end

  def current
    Staydesk::AgentStatusPeriod.current.includes(:agent_status).find_by(account_user: @account_user)&.agent_status
  end

  def change_to(agent_status, at: Time.current)
    Staydesk::AgentStatusPeriod.transaction do
      fechar_periodo_aberto(at)
      Staydesk::AgentStatusPeriod.create!(account: @account_user.account, account_user: @account_user,
                                          agent_status: agent_status, started_at: at, last_connected_at: at)
    end
    alinhar_disponibilidade(agent_status.availability)
    # Ficou disponível: o que está parado na fila é oferecido agora, não no
    # próximo minuto do cron nem na próxima mensagem do cliente.
    Staydesk::Queues::SweepJob.perform_later(@account_user.account_id) if agent_status.availability == 'online'
    agent_status
  end

  def clear(at: Time.current)
    fechar_periodo_aberto(at)
  end

  # Carimbo de que a pessoa está conectada, para o tempo limite contar do último
  # sinal de vida e não do começo do status.
  def registrar_presenca!(periodo, at: Time.current)
    # rubocop:disable Rails/SkipsModelValidations
    periodo.update_column(:last_connected_at, at)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def passou_do_limite?(periodo, now: Time.current)
    limite = periodo.agent_status&.offline_after_seconds
    return false if limite.blank?

    (periodo.last_connected_at || periodo.started_at) < now - limite.seconds
  end

  # Fechou a aba e passou do tempo: o período fecha, a disponibilidade vai a
  # offline e, se o status tiver destino, o agente cai nele.
  def desconectar!(periodo, at: Time.current)
    destino = periodo.agent_status&.offline_to_status
    return change_to(destino, at: at) if destino.present?

    fechar_periodo_aberto(at)
    alinhar_disponibilidade('offline')
    nil
  end

  private

  # A distribuição e os números leem a disponibilidade do Redis, não do banco.
  # Sem alinhar os dois, o agente fica "online" no banco e "offline" na roda, e
  # não recebe nada sem ninguém entender por quê.
  # O AccountUser já espelha a disponibilidade no Redis quando ela muda; o
  # espelho explícito cobre o caso em que o banco já estava certo e só o Redis
  # ficou para trás (foi assim que um agente "online" sumiu da distribuição).
  def alinhar_disponibilidade(disponibilidade)
    @account_user.update!(availability: disponibilidade)
    return if @account_user.saved_change_to_availability?

    OnlineStatusTracker.set_status(@account_user.account_id, @account_user.user_id, disponibilidade)
  end

  # Fecha o período aberto em bloco: é carimbo de hora, não tem o que validar.
  def fechar_periodo_aberto(at)
    # rubocop:disable Rails/SkipsModelValidations
    Staydesk::AgentStatusPeriod.current.where(account_user: @account_user).update_all(ended_at: at)
    # rubocop:enable Rails/SkipsModelValidations
  end
end

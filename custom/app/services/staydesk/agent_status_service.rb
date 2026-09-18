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
                                          agent_status: agent_status, started_at: at)
    end
    @account_user.update!(availability: agent_status.availability)
    # Ficou disponível: o que está parado na fila é oferecido agora, não no
    # próximo minuto do cron nem na próxima mensagem do cliente.
    Staydesk::Queues::SweepJob.perform_later(@account_user.account_id) if agent_status.availability == 'online'
    agent_status
  end

  def clear(at: Time.current)
    fechar_periodo_aberto(at)
  end

  private

  # Fecha o período aberto em bloco: é carimbo de hora, não tem o que validar.
  def fechar_periodo_aberto(at)
    # rubocop:disable Rails/SkipsModelValidations
    Staydesk::AgentStatusPeriod.current.where(account_user: @account_user).update_all(ended_at: at)
    # rubocop:enable Rails/SkipsModelValidations
  end
end

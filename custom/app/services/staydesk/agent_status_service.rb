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
      Staydesk::AgentStatusPeriod.current.where(account_user: @account_user).update_all(ended_at: at)
      Staydesk::AgentStatusPeriod.create!(account: @account_user.account, account_user: @account_user,
                                          agent_status: agent_status, started_at: at)
    end
    @account_user.update!(availability: agent_status.availability)
    agent_status
  end

  def clear(at: Time.current)
    Staydesk::AgentStatusPeriod.current.where(account_user: @account_user).update_all(ended_at: at)
  end
end

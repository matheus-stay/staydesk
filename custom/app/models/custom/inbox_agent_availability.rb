# Entra no concern InboxAgentAvailability pelo gancho prepend_mod_with. Dois filtros
# da camada StayDesk: a distribuição automática pula quem está num status que não
# atende esta caixa (SPEC-09) e quem já bateu o limite de conversas simultâneas da
# fila desta caixa (SPEC-11).
module Custom::InboxAgentAvailability
  def available_agents
    members = super
    return members if members.blank?

    members = reject_statuses_without_inbox(members)
    return members if members.blank?

    reject_agents_without_capacity(members)
  end

  private

  def reject_statuses_without_inbox(members)
    excluded = Staydesk::AgentStatusPeriod.current
                                          .joins(:agent_status)
                                          .where(account_user: account.account_users.where(user_id: members.map(&:user_id)))
                                          .where.not(Staydesk::AgentStatus.arel_table[:inbox_ids].eq('{}'))
                                          .where.not('? = ANY(staydesk_agent_statuses.inbox_ids)', id)
                                          .joins(:account_user).pluck('account_users.user_id')
    return members if excluded.empty?

    members.where.not(user_id: excluded)
  end

  def reject_agents_without_capacity(members)
    full = Staydesk::AgentLoadService.new(account).over_capacity(self, members.map(&:user_id))
    return members if full.empty?

    members.where.not(user_id: full)
  end
end

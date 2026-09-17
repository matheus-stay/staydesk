# Entra no concern InboxAgentAvailability pelo gancho prepend_mod_with: a distribuição
# automática pula quem está num status que não atende esta caixa de entrada.
module Custom::InboxAgentAvailability
  def available_agents
    members = super
    return members if members.blank?

    excluded = Staydesk::AgentStatusPeriod.current
                                          .joins(:agent_status)
                                          .where(account_user: account.account_users.where(user_id: members.map(&:user_id)))
                                          .where.not(Staydesk::AgentStatus.arel_table[:inbox_ids].eq('{}'))
                                          .where.not('? = ANY(staydesk_agent_statuses.inbox_ids)', id)
                                          .joins(:account_user).pluck('account_users.user_id')
    return members if excluded.empty?

    members.where.not(user_id: excluded)
  end
end

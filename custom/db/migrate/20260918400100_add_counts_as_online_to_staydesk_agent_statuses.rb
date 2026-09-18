class AddCountsAsOnlineToStaydeskAgentStatuses < ActiveRecord::Migration[7.1]
  def up
    add_column :staydesk_agent_statuses, :counts_as_online, :boolean, null: false, default: true
    # O que já existe segue a regra antiga: status disponível conta, ausente não.
    execute "UPDATE staydesk_agent_statuses SET counts_as_online = (availability = 'online')"
  end

  def down
    remove_column :staydesk_agent_statuses, :counts_as_online
  end
end

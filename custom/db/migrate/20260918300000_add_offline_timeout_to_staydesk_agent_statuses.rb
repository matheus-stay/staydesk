class AddOfflineTimeoutToStaydeskAgentStatuses < ActiveRecord::Migration[7.1]
  def change
    add_column :staydesk_agent_statuses, :offline_after_seconds, :integer, default: 300
    add_column :staydesk_agent_statuses, :offline_to_status_id, :bigint
    add_column :staydesk_agent_status_periods, :last_connected_at, :datetime
  end
end

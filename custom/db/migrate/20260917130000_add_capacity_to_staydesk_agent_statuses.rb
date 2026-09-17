class AddCapacityToStaydeskAgentStatuses < ActiveRecord::Migration[7.1]
  def change
    add_column :staydesk_agent_statuses, :capacity, :jsonb, null: false, default: {}
  end
end

class AddUniqueIndexToStaydeskAgentStatuses < ActiveRecord::Migration[7.1]
  def change
    add_index :staydesk_agent_statuses, [:account_id, :name], unique: true
  end
end

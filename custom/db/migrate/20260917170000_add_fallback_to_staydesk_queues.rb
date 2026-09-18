class AddFallbackToStaydeskQueues < ActiveRecord::Migration[7.1]
  def change
    add_column :staydesk_queues, :fallback_team_id, :bigint
    add_column :staydesk_queues, :fallback_after_minutes, :integer
  end
end

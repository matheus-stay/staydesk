class ChangeStaydeskQueueFallbackToList < ActiveRecord::Migration[7.1]
  def up
    add_column :staydesk_queues, :fallback_team_ids, :bigint, array: true, null: false, default: []
    execute <<~SQL.squish
      UPDATE staydesk_queues SET fallback_team_ids = ARRAY[fallback_team_id]
      WHERE fallback_team_id IS NOT NULL
    SQL
    remove_column :staydesk_queues, :fallback_team_id
  end

  def down
    add_column :staydesk_queues, :fallback_team_id, :bigint
    execute 'UPDATE staydesk_queues SET fallback_team_id = fallback_team_ids[1]'
    remove_column :staydesk_queues, :fallback_team_ids
  end
end

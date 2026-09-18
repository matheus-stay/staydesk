class AddTeamIdsToStaydeskQueues < ActiveRecord::Migration[7.1]
  # A fila passa a ter grupos principais (vários) e grupos secundários, como no
  # Zendesk. O modo "ajuda sempre" era um grupo principal a mais; vira isso.
  def up
    add_column :staydesk_queues, :team_ids, :bigint, array: true, default: [], null: false
    execute <<~SQL.squish
      UPDATE staydesk_queues
      SET team_ids = CASE WHEN fallback_mode = 'sempre' THEN ARRAY[team_id] || fallback_team_ids ELSE ARRAY[team_id] END,
          fallback_team_ids = CASE WHEN fallback_mode = 'sempre' THEN '{}'::bigint[] ELSE fallback_team_ids END
    SQL
    remove_column :staydesk_queues, :fallback_mode
  end

  def down
    add_column :staydesk_queues, :fallback_mode, :string, default: 'quando_faltar', null: false
    remove_column :staydesk_queues, :team_ids
  end
end

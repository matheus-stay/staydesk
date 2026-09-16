class CreateStaydeskTeamWorkspaces < ActiveRecord::Migration[7.1]
  def change
    create_table :staydesk_team_workspaces do |t|
      t.references :account, null: false
      t.bigint :team_id
      t.jsonb :config, null: false, default: {}
      t.timestamps
    end

    add_index :staydesk_team_workspaces, [:account_id, :team_id], unique: true, nulls_not_distinct: true
  end
end

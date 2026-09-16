class CreateStaydeskTeamViews < ActiveRecord::Migration[7.1]
  def change
    create_table :staydesk_team_views do |t|
      t.references :account, null: false
      t.string :name, null: false
      t.string :description
      t.string :color
      t.string :icon
      t.jsonb :query, null: false, default: {}
      t.jsonb :columns, null: false, default: []
      t.string :sort_by
      t.integer :position, null: false, default: 0
      t.bigint :team_ids, array: true, null: false, default: []
      t.bigint :created_by_id
      t.timestamps
    end

    add_index :staydesk_team_views, :team_ids, using: :gin
    add_index :staydesk_team_views, [:account_id, :position]
  end
end

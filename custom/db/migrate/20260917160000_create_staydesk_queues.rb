class CreateStaydeskQueues < ActiveRecord::Migration[7.1]
  def change
    create_table :staydesk_queues do |t|
      t.references :account, null: false
      t.bigint :team_id, null: false
      t.string :name, null: false
      t.string :description
      t.jsonb :conditions, null: false, default: []
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :staydesk_queues, [:account_id, :name], unique: true
    add_index :staydesk_queues, [:account_id, :position]
  end
end

class CreateStaydeskLoadQueues < ActiveRecord::Migration[7.1]
  def change
    create_table :staydesk_load_queues do |t|
      t.references :account, null: false, index: true
      t.string :key, null: false
      t.string :name, null: false
      t.string :channel_types, array: true, null: false, default: []
      t.boolean :catch_all, null: false, default: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :staydesk_load_queues, [:account_id, :key], unique: true
  end
end

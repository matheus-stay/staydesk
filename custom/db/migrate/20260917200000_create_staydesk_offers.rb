class CreateStaydeskOffers < ActiveRecord::Migration[7.1]
  def change
    add_column :staydesk_queues, :accept_required, :boolean, null: false, default: false
    add_column :staydesk_queues, :accept_timeout_seconds, :integer, null: false, default: 30

    create_table :staydesk_offers do |t|
      t.references :account, null: false
      t.bigint :conversation_id, null: false
      t.bigint :user_id, null: false
      t.string :status, null: false, default: 'pendente'
      t.datetime :expires_at, null: false
      t.datetime :answered_at
      t.timestamps
    end
    add_index :staydesk_offers, [:user_id, :status]
    add_index :staydesk_offers, [:conversation_id, :status]
  end
end

class CreateStaydeskImpersonations < ActiveRecord::Migration[7.1]
  def change
    create_table :staydesk_impersonations do |t|
      t.references :account, null: false
      t.bigint :actor_id, null: false
      t.bigint :target_id, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :staydesk_impersonations, [:account_id, :created_at]
  end
end

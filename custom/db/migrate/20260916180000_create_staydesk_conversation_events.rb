class CreateStaydeskConversationEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :staydesk_conversation_events do |t|
      t.references :account, null: false
      t.references :conversation, null: false
      t.string :kind, null: false
      t.string :from_value
      t.string :to_value
      t.bigint :user_id
      t.datetime :created_at, null: false
    end

    add_index :staydesk_conversation_events, [:account_id, :created_at]
    add_index :staydesk_conversation_events, [:account_id, :kind, :created_at]
  end
end

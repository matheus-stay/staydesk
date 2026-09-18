class CreateStaydeskApiTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :staydesk_api_tokens do |t|
      t.references :account, null: false, index: true
      t.references :user, null: false, index: true
      t.string :name, null: false
      t.string :description
      t.string :token_digest, null: false
      t.string :token_hint, null: false
      t.string :scopes, array: true, null: false, default: []
      t.datetime :expires_at
      t.datetime :last_used_at
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :staydesk_api_tokens, :token_digest, unique: true
  end
end

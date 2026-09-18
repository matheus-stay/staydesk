class CreateStaydeskRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :staydesk_roles do |t|
      t.references :account, null: false
      t.string :name, null: false
      t.string :description
      t.string :permissions, array: true, null: false, default: []
      t.boolean :built_in, null: false, default: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :staydesk_roles, [:account_id, :name], unique: true

    add_reference :staydesk_account_user_roles, :staydesk_role, null: true
  end
end

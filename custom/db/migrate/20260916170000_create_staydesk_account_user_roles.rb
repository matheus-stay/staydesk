class CreateStaydeskAccountUserRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :staydesk_account_user_roles do |t|
      t.references :account_user, null: false, index: { unique: true }
      t.string :kind, null: false, default: 'full'
      t.timestamps
    end
  end
end

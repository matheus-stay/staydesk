class CreateStaydeskTicketStatuses < ActiveRecord::Migration[7.1]
  def change
    create_table :staydesk_ticket_statuses do |t|
      t.references :account, null: false
      t.string :name, null: false
      t.string :description
      t.string :color
      t.string :base_status, null: false
      t.boolean :default_for_base, null: false, default: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :staydesk_ticket_statuses, [:account_id, :position]
    add_index :staydesk_ticket_statuses, [:account_id, :name], unique: true
  end
end

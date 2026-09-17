class CreateStaydeskAgentStatuses < ActiveRecord::Migration[7.1]
  def change
    create_table :staydesk_agent_statuses do |t|
      t.references :account, null: false
      t.string :name, null: false
      t.string :color
      t.string :availability, null: false, default: 'online'
      t.bigint :inbox_ids, array: true, null: false, default: []
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    create_table :staydesk_agent_status_periods do |t|
      t.references :account, null: false
      t.references :account_user, null: false
      t.references :agent_status, null: false
      t.datetime :started_at, null: false
      t.datetime :ended_at
    end

    add_index :staydesk_agent_status_periods, [:account_user_id, :ended_at]
    add_index :staydesk_agent_status_periods, [:account_id, :started_at]
  end
end

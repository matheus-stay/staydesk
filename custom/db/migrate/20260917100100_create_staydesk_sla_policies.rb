class CreateStaydeskSlaPolicies < ActiveRecord::Migration[7.1]
  def change
    create_table :staydesk_sla_policies do |t|
      t.references :account, null: false
      t.string :name, null: false
      t.string :description
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.jsonb :conditions, null: false, default: []
      t.jsonb :targets, null: false, default: {}
      t.bigint :calendar_id
      t.string :pause_statuses, array: true, null: false, default: %w[pending snoozed]
      t.decimal :warning_ratio, precision: 3, scale: 2, null: false, default: 0.2
      t.timestamps
    end

    add_index :staydesk_sla_policies, [:account_id, :position]
  end
end

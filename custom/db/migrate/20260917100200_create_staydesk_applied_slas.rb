class CreateStaydeskAppliedSlas < ActiveRecord::Migration[7.1]
  def change
    create_table :staydesk_applied_slas do |t|
      t.references :account, null: false
      t.references :conversation, null: false, index: { unique: true }
      t.references :sla_policy, null: false
      t.string :status, null: false, default: 'running'
      t.datetime :first_response_due_at
      t.datetime :first_response_met_at
      t.datetime :next_response_due_at
      t.datetime :next_response_met_at
      t.datetime :resolution_due_at
      t.datetime :resolution_met_at
      t.datetime :paused_at
      t.integer :paused_seconds, null: false, default: 0
      t.string :breached_metrics, array: true, null: false, default: []
      t.string :warned_metrics, array: true, null: false, default: []
      t.timestamps
    end

    add_index :staydesk_applied_slas, [:account_id, :status]
    add_index :staydesk_applied_slas, [:account_id, :updated_at]
  end
end

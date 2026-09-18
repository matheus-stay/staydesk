class AddFallbackModeToStaydeskQueues < ActiveRecord::Migration[7.1]
  def change
    add_column :staydesk_queues, :fallback_mode, :string, null: false, default: 'quando_faltar'
  end
end

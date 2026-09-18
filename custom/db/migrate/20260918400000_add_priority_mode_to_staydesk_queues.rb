class AddPriorityModeToStaydeskQueues < ActiveRecord::Migration[7.1]
  def change
    add_column :staydesk_queues, :priority_mode, :string, null: false, default: 'chegada'
  end
end

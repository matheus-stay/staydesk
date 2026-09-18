class AddInboxIdsToStaydeskLoadQueues < ActiveRecord::Migration[7.1]
  def change
    add_column :staydesk_load_queues, :inbox_ids, :bigint, array: true, null: false, default: []
  end
end

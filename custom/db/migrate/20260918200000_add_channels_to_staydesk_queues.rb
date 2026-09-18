class AddChannelsToStaydeskQueues < ActiveRecord::Migration[7.1]
  def change
    add_column :staydesk_queues, :channel_types, :string, array: true, null: false, default: []
    add_column :staydesk_queues, :inbox_ids, :bigint, array: true, null: false, default: []
  end
end

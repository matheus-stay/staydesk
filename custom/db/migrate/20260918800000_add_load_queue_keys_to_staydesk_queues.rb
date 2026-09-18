class AddLoadQueueKeysToStaydeskQueues < ActiveRecord::Migration[7.1]
  # A fila pode dizer o que entra pelo nome do canal de trabalho ("Chat e
  # WhatsApp"), além do tipo de canal e do canal específico.
  def change
    add_column :staydesk_queues, :load_queue_keys, :string, array: true, null: false, default: []
  end
end

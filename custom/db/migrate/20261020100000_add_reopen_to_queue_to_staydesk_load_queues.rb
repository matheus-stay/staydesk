class AddReopenToQueueToStaydeskLoadQueues < ActiveRecord::Migration[7.1]
  # Como no Zendesk: chat encerrado que o cliente reabre volta para a fila, sem
  # o agente anterior; ticket reaberto continua com quem atendia. É por canal de
  # trabalho, então mora na fila de carga.
  def change
    add_column :staydesk_load_queues, :reopen_to_queue, :boolean, default: false, null: false
  end
end

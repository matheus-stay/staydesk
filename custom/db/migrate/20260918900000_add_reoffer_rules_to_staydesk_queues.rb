class AddReofferRulesToStaydeskQueues < ActiveRecord::Migration[7.1]
  # O que acontece com o convite não aceito quando não há mais ninguém: oferece
  # de novo ao mesmo agente (e depois de quanto tempo), como no Zendesk.
  def change
    add_column :staydesk_queues, :reoffer_same_agent, :boolean, null: false, default: true
    add_column :staydesk_queues, :reoffer_after_seconds, :integer, null: false, default: 0
  end
end

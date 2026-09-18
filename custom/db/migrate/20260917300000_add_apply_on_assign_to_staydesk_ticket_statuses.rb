class AddApplyOnAssignToStaydeskTicketStatuses < ActiveRecord::Migration[7.1]
  def change
    add_column :staydesk_ticket_statuses, :apply_on_assign, :boolean, default: false, null: false
  end
end

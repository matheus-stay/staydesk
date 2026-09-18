class AddUniqueIndexesToStaydeskCatalogs < ActiveRecord::Migration[7.1]
  def change
    add_index :staydesk_team_views, [:account_id, :name], unique: true
    add_index :staydesk_sla_policies, [:account_id, :name], unique: true
    add_index :staydesk_calendars, [:account_id, :name], unique: true
  end
end

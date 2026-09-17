class CreateStaydeskCalendars < ActiveRecord::Migration[7.1]
  def change
    create_table :staydesk_calendars do |t|
      t.references :account, null: false
      t.string :name, null: false
      t.string :timezone, null: false, default: 'America/Sao_Paulo'
      t.jsonb :weekly_hours, null: false, default: []
      t.jsonb :holidays, null: false, default: []
      t.timestamps
    end
  end
end

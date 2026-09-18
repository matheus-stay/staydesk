class EveryoneServesEveryChannel < ActiveRecord::Migration[7.1]
  # Todo agente atende todos os canais, como no Zendesk: o que já existia entra
  # nos canais em que ainda não estava. Daqui em diante os ganchos mantêm.
  def up
    execute <<~SQL.squish
      INSERT INTO inbox_members (user_id, inbox_id, created_at, updated_at)
      SELECT au.user_id, i.id, NOW(), NOW()
      FROM account_users au
      JOIN inboxes i ON i.account_id = au.account_id
      LEFT JOIN inbox_members im ON im.user_id = au.user_id AND im.inbox_id = i.id
      WHERE im.id IS NULL
    SQL
  end

  def down; end
end

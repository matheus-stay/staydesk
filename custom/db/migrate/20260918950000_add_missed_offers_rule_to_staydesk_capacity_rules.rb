class AddMissedOffersRuleToStaydeskCapacityRules < ActiveRecord::Migration[7.1]
  # Como no Zendesk: quem deixa vencer (ou recusa) N convites seguidos cai para
  # um status de ausência e para de contar tempo online. A regra mora na regra
  # de capacidade, que é o que já agrupa os agentes.
  def change
    add_column :staydesk_capacity_rules, :missed_offers_limit, :integer
    add_column :staydesk_capacity_rules, :missed_offers_to_status_id, :bigint
  end
end

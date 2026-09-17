# == Schema Information
#
# Table name: staydesk_ticket_statuses
#
#  id               :bigint           not null, primary key
#  active           :boolean          default(TRUE), not null
#  base_status      :string           not null  (open | pending | snoozed | resolved)
#  color            :string
#  default_for_base :boolean          default(FALSE), not null
#  description      :string
#  name             :string           not null
#  position         :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#
# Status personalizado do ticket, em cima dos quatro status fixos do Chatwoot.
# O status escolhido fica no atributo de conversa `staydesk_status` (definição de
# lista mantida em dia por este modelo), então filtros, views e automações o usam.
class Staydesk::TicketStatus < ApplicationRecord
  self.table_name = 'staydesk_ticket_statuses'

  ATTRIBUTE_KEY = 'staydesk_status'.freeze
  BASE_STATUSES = Conversation.statuses.keys.freeze

  belongs_to :account

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :base_status, inclusion: { in: BASE_STATUSES }

  after_commit :sync_attribute_definition

  scope :ordered, -> { order(:position, :id) }
  scope :active, -> { where(active: true) }

  # O status que representa um status base quando a mudança veio de fora do seletor.
  def self.default_for(account, base_status)
    scope = active.where(account: account, base_status: base_status).ordered
    scope.find_by(default_for_base: true) || scope.first
  end

  private

  # Uma definição de atributo de lista com os nomes ativos, para o resto do Chatwoot enxergar.
  def sync_attribute_definition
    names = self.class.active.where(account: account).ordered.pluck(:name)
    definition = CustomAttributeDefinition.find_or_initialize_by(
      account: account, attribute_key: ATTRIBUTE_KEY, attribute_model: 'conversation_attribute'
    )
    definition.attribute_display_name = 'Status do ticket' if definition.attribute_display_name.blank?
    definition.attribute_display_type = 'list'
    definition.attribute_values = names
    definition.save!
  end
end

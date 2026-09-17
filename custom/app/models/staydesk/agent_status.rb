# == Schema Information
#
# Table name: staydesk_agent_statuses
#
#  id           :bigint           not null, primary key
#  active       :boolean          default(TRUE), not null
#  availability :string           default("online"), not null   (online | busy)
#  color        :string
#  inbox_ids    :bigint           default([]), not null, is an Array  (vazio = todas as caixas)
#  name         :string           not null
#  position     :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#
# Status personalizado do agente: o que ele atende agora. A distribuição automática
# só entrega conversas das caixas que o status atende.
class Staydesk::AgentStatus < ApplicationRecord
  self.table_name = 'staydesk_agent_statuses'

  AVAILABILITIES = %w[online busy].freeze

  belongs_to :account
  has_many :periods, class_name: 'Staydesk::AgentStatusPeriod', foreign_key: :agent_status_id, dependent: :destroy, inverse_of: :agent_status

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :availability, inclusion: { in: AVAILABILITIES }

  scope :ordered, -> { order(:position, :id) }
  scope :active, -> { where(active: true) }

  def serves_inbox?(inbox_id)
    inbox_ids.empty? || inbox_ids.include?(inbox_id)
  end
end

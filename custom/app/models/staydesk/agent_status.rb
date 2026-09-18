# == Schema Information
#
# Table name: staydesk_agent_statuses
#
#  id           :bigint           not null, primary key
#  active       :boolean          default(TRUE), not null
#  availability :string           default("online"), not null   (online | busy)
#  capacity     :jsonb            default({}), not null  ({"chat" => 5, "ticket" => 12}; ausente = sem limite)
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
  has_many :periods, class_name: 'Staydesk::AgentStatusPeriod', dependent: :destroy, inverse_of: :agent_status

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :availability, inclusion: { in: AVAILABILITIES }
  validate :capacity_must_be_whole_numbers

  before_validation :normalize_capacity

  scope :ordered, -> { order(:position, :id) }
  scope :active, -> { where(active: true) }

  def serves_inbox?(inbox_id)
    inbox_ids.empty? || inbox_ids.include?(inbox_id)
  end

  # Quantas conversas simultâneas desta fila o agente aceita neste status.
  # nil = sem limite; 0 = não recebe distribuição automática desta fila.
  def capacity_for(queue)
    value = (capacity || {})[queue.to_s]
    return nil if value.blank? && value != 0

    value.to_i
  end

  private

  def normalize_capacity
    self.capacity = (capacity || {}).slice(*filas_de_carga).filter_map do |queue, value|
      next if value.nil? || value.to_s.strip.empty?

      [queue, value.to_i]
    end.to_h
  end

  # Sem conta ainda (registro novo em validação), vale o padrão do produto.
  def filas_de_carga
    account ? Staydesk::LoadQueue.keys_for(account) : Staydesk::LoadQueue::DEFAULTS.pluck(:key)
  end

  def capacity_must_be_whole_numbers
    return if (capacity || {}).values.all? { |value| value.is_a?(Integer) && value >= 0 }

    errors.add(:capacity, 'deve ter números inteiros a partir de zero')
  end
end

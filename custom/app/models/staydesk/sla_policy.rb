# == Schema Information
#
# Table name: staydesk_sla_policies
#
#  id             :bigint           not null, primary key
#  active         :boolean          default(TRUE), not null
#  conditions     :jsonb            not null  (payload do filtro avançado / automação)
#  description    :string
#  name           :string           not null
#  pause_statuses :string           default(["pending", "snoozed"]), not null, is an Array
#  position       :integer          default(0), not null
#  targets        :jsonb            not null  ({ "default": { "first_response": 60, "next_response": 120, "resolution": 480 }, "urgent": {...} })
#  warning_ratio  :decimal(3, 2)    default(0.2), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#  calendar_id    :bigint           (nulo = relógio de parede)
#
class Staydesk::SlaPolicy < ApplicationRecord
  self.table_name = 'staydesk_sla_policies'

  METRICS = %w[first_response next_response resolution].freeze
  PRIORITIES = %w[default urgent high medium low].freeze

  belongs_to :account
  belongs_to :calendar, class_name: 'Staydesk::Calendar', optional: true
  # As medições em curso não sobrevivem à política: a coluna é obrigatória e o
  # histórico que importa fica nos eventos de SLA e nos atributos da conversa.
  has_many :applied_slas, class_name: 'Staydesk::AppliedSla', dependent: :destroy, inverse_of: :sla_policy

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :warning_ratio, numericality: { greater_than: 0, less_than: 1 }
  validate :conditions_shape
  validate :targets_shape

  scope :ordered, -> { order(:position, :id) }
  scope :active, -> { where(active: true) }

  # Alvo em minutos para a métrica na prioridade da conversa; cai no padrão.
  def target_minutes(metric, priority)
    value = targets.dig(priority.to_s, metric.to_s).presence || targets.dig('default', metric.to_s).presence
    value&.to_i
  end

  def clock
    calendar&.business_time || Staydesk::Sla::BusinessTime.wall_clock
  end

  private

  def conditions_shape
    return if conditions.is_a?(Array) && conditions.all? { |c| c.is_a?(Hash) && c['attribute_key'].present? && c['filter_operator'].present? }

    errors.add(:conditions, 'must be a list of { attribute_key, filter_operator, values, query_operator }')
  end

  def targets_shape
    return if targets.is_a?(Hash) && targets.keys.all? { |k| PRIORITIES.include?(k) } &&
              targets.values.all? { |v| v.is_a?(Hash) && (v.keys - METRICS).empty? }

    errors.add(:targets, "must map #{PRIORITIES.join(', ')} to { #{METRICS.join(', ')} } in minutes")
  end
end

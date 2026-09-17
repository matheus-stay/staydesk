# == Schema Information
#
# Table name: staydesk_applied_slas
#
#  id                    :bigint           not null, primary key
#  breached_metrics      :string           default([]), not null, is an Array
#  first_response_due_at :datetime
#  first_response_met_at :datetime
#  next_response_due_at  :datetime
#  next_response_met_at  :datetime
#  paused_at             :datetime
#  paused_seconds        :integer          default(0), not null
#  resolution_due_at     :datetime
#  resolution_met_at     :datetime
#  status                :string           default("running"), not null
#  warned_metrics        :string           default([]), not null, is an Array
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#  conversation_id       :bigint           not null
#  sla_policy_id         :bigint           not null
#
# O SLA em andamento de uma conversa: prazos das três métricas, pausa e o que já venceu.
class Staydesk::AppliedSla < ApplicationRecord
  self.table_name = 'staydesk_applied_slas'

  STATUSES = %w[running warning breached paused met].freeze
  OPEN_STATUSES = %w[running warning breached].freeze

  belongs_to :account
  belongs_to :conversation
  belongs_to :sla_policy, class_name: 'Staydesk::SlaPolicy'

  validates :status, inclusion: { in: STATUSES }

  scope :open, -> { where(status: OPEN_STATUSES) }

  def paused?
    paused_at.present?
  end

  # Métricas ainda correndo, com o prazo mais próximo primeiro.
  def pending_metrics
    Staydesk::SlaPolicy::METRICS.filter_map do |metric|
      due = public_send("#{metric}_due_at")
      met = public_send("#{metric}_met_at")
      [metric, due] if due.present? && met.blank?
    end.sort_by(&:last)
  end

  def next_due_at
    pending_metrics.first&.last
  end

  # O que o selo e o dashboard leem na conversa.
  def conversation_attributes
    {
      'sla_alvo' => sla_policy.name,
      'sla_status' => status,
      'sla_vence_em' => next_due_at&.iso8601
    }
  end
end

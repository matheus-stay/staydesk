# == Schema Information
#
# Table name: staydesk_agent_statuses
#
#  id           :bigint           not null, primary key
#  active       :boolean          default(TRUE), not null
#  availability :string           default("online"), not null   (online | busy)
#  work_channels :string          default([]), not null, is an Array  (chaves das filas de carga que o status recebe)
#  color        :string
#  inbox_ids    :bigint           default([]), not null, is an Array  (vazio = todas as caixas)
#  name         :string           not null
#  position     :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#
# Status personalizado do agente: o que ele atende agora, por canal de trabalho,
# como no Zendesk. A distribuição automática só entrega conversas dos canais e
# das caixas que o status atende; quanto entrega é da regra de capacidade.
class Staydesk::AgentStatus < ApplicationRecord
  self.table_name = 'staydesk_agent_statuses'

  AVAILABILITIES = %w[online busy].freeze

  belongs_to :account
  # Tempo limite do status, como no Zendesk: desconectado por mais que
  # `offline_after_seconds`, o agente cai em `offline_to_status` (ou fica sem
  # status, que é offline). Nulo em segundos desliga a regra para este status.
  belongs_to :offline_to_status, class_name: 'Staydesk::AgentStatus', optional: true
  has_many :periods, class_name: 'Staydesk::AgentStatusPeriod', dependent: :destroy, inverse_of: :agent_status

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :availability, inclusion: { in: AVAILABILITIES }
  validates :offline_after_seconds, numericality: { greater_than_or_equal_to: 30 }, allow_nil: true
  validate :offline_target_is_another_status_of_the_account

  before_validation :normalize_work_channels

  scope :ordered, -> { order(:position, :id) }
  scope :active, -> { where(active: true) }

  def serves_inbox?(inbox_id)
    inbox_ids.empty? || inbox_ids.include?(inbox_id)
  end

  # Este status recebe conversas deste canal de trabalho (chave da fila de carga)?
  def receives?(queue)
    work_channels.include?(queue.to_s)
  end

  private

  # Só chaves que a conta conhece, na ordem das filas de carga.
  def normalize_work_channels
    self.work_channels = filas_de_carga & Array(work_channels).map(&:to_s)
  end

  # Sem conta ainda (registro novo em validação), vale o padrão do produto.
  def filas_de_carga
    account ? Staydesk::LoadQueue.keys_for(account) : Staydesk::LoadQueue::DEFAULTS.pluck(:key)
  end

  def offline_target_is_another_status_of_the_account
    return if offline_to_status.blank?

    errors.add(:offline_to_status_id, 'não pode ser o próprio status') if offline_to_status_id == id
    errors.add(:offline_to_status_id, 'precisa ser um status desta conta') if offline_to_status.account_id != account_id
  end
end

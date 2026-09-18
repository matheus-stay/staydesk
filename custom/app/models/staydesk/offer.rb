# == Schema Information
#
# Table name: staydesk_offers
#
#  id              :bigint           not null, primary key
#  status          :string           default("pendente"), not null  (pendente|aceita|recusada|expirada)
#  expires_at      :datetime         not null
#  answered_at     :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  user_id         :bigint           not null
#
# Convite de atendimento (SPEC-16): em chat e WhatsApp a conversa é oferecida ao
# agente e ele precisa aceitar, como no Zendesk. Se não aceitar no tempo da fila,
# volta para a distribuição e o mesmo agente fica de fora da próxima escolha.
class Staydesk::Offer < ApplicationRecord
  self.table_name = 'staydesk_offers'

  STATUSES = %w[pendente aceita recusada expirada].freeze

  belongs_to :account
  belongs_to :conversation
  belongs_to :user

  validates :status, inclusion: { in: STATUSES }

  scope :pendentes, -> { where(status: 'pendente') }
  scope :vencidas, -> { pendentes.where(expires_at: ...Time.current) }

  def pendente?
    status == 'pendente'
  end

  def segundos_restantes
    [(expires_at - Time.current).to_i, 0].max
  end
end

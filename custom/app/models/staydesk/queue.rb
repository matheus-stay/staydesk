# == Schema Information
#
# Table name: staydesk_queues
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE), not null
#  conditions  :jsonb            default([]), not null  (payload do filtro avançado; vazio = pega tudo)
#  description :string
#  name        :string           not null
#  position    :integer          default(0), not null   (menor número decide primeiro)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  team_id     :bigint           not null                (o time que recebe)
#  fallback_team_ids      :bigint   default([]), not null, is an Array  (grupos que ajudam)
#  fallback_mode          :string   default("quando_faltar"), not null   (sempre | quando_faltar)
#  fallback_after_minutes :integer  (nulo = transborda na hora; com valor, espera esses minutos)
#
# Fila de encaminhamento (SPEC-15), no modelo do Zendesk: a conversa que chega é
# comparada com as filas em ordem e a primeira que casar entrega ao time dela. Quem
# dentro do time vai atender continua sendo decidido pelo status e pela carga do
# agente (SPEC-09 e SPEC-11).
class Staydesk::Queue < ApplicationRecord
  self.table_name = 'staydesk_queues'

  # `sempre`: os grupos que ajudam trabalham esta fila junto com o dono, como o N3
  # que atende ticket de N2 no tempo livre. `quando_faltar`: só entram quando o dono
  # está sem ninguém disponível.
  FALLBACK_MODES = %w[sempre quando_faltar].freeze

  belongs_to :account
  belongs_to :team

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :fallback_after_minutes, numericality: { greater_than: 0 }, allow_nil: true
  validates :fallback_mode, inclusion: { in: FALLBACK_MODES }
  validate :conditions_shape
  validate :fallback_is_another_team

  scope :with_fallback, -> { active.where.not(fallback_team_ids: []) }

  scope :ordered, -> { order(:position, :id) }
  scope :active, -> { where(active: true) }

  # Os grupos que ajudam nesta fila, além do dono.
  def fallback_teams
    account.teams.where(id: fallback_team_ids)
  end

  private

  def fallback_is_another_team
    errors.add(:fallback_team_ids, 'não pode incluir o time que já recebe') if fallback_team_ids.include?(team_id)
  end

  def conditions_shape
    return if conditions.is_a?(Array) && conditions.all? { |c| c.is_a?(Hash) && c['attribute_key'].present? && c['filter_operator'].present? }

    errors.add(:conditions, 'must be a list of { attribute_key, filter_operator, values, query_operator }')
  end
end

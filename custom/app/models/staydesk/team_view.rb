# == Schema Information
#
# Table name: staydesk_team_views
#
#  id            :bigint           not null, primary key
#  columns       :jsonb            not null
#  color         :string
#  description   :string
#  icon          :string
#  name          :string           not null
#  position      :integer          default(0), not null
#  query         :jsonb            not null
#  sort_by       :string
#  team_ids      :bigint           default([]), not null, is an Array
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  created_by_id :bigint
#
# Uma view compartilhada: a mesma consulta do filtro avançado (`query.payload`),
# visível aos times listados em `team_ids` (vazio = conta inteira), com colunas
# e ordenação próprias para a lista em tabela.
class Staydesk::TeamView < ApplicationRecord
  self.table_name = 'staydesk_team_views'

  COLUMNS = %w[sla status subject contact inbox created_at waiting_since assignee team priority labels].freeze
  CURRENT_USER_TOKEN = 'me'.freeze
  USER_FIELDS = %w[assignee_id created_by_id].freeze
  DEFAULT_COLUMNS = %w[sla status subject contact waiting_since assignee].freeze

  belongs_to :account
  belongs_to :created_by, class_name: 'User', optional: true

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :sort_by, inclusion: { in: ->(_view) { Conversations::SortService::SORT_OPTIONS.keys.map(&:to_s) } }, allow_blank: true
  validate :query_has_payload
  validate :columns_are_known

  scope :ordered, -> { order(:position, :id) }

  def self.visible_to(user, account)
    da_conta = where(account_id: account.id)
    team_ids = user.teams.where(account_id: account.id).ids
    return da_conta.where(team_ids: []) if team_ids.empty?

    da_conta.where("team_ids = '{}' OR team_ids && ARRAY[:ids]::bigint[]", ids: team_ids)
  end

  def teams
    account.teams.where(id: team_ids)
  end

  # Marcador dinâmico, como as views do Zendesk: `me` no valor de um filtro vira
  # o id de quem está pedindo. É o que faz a mesma view servir a todo agente.
  def payload(user = nil)
    linhas = query['payload'] || []
    return linhas if user.blank?

    linhas.map { |linha| resolver_marcador(linha, user) }
  end

  private

  def resolver_marcador(linha, user)
    return linha unless USER_FIELDS.include?(linha['attribute_key'].to_s)

    valores = Array(linha['values']).map { |valor| valor.to_s == CURRENT_USER_TOKEN ? user.id : valor }
    linha.merge('values' => valores)
  end

  def query_has_payload
    return if query.is_a?(Hash) && query['payload'].is_a?(Array)

    errors.add(:query, 'must contain a payload array')
  end

  def columns_are_known
    return if columns.is_a?(Array) && (columns - COLUMNS).empty?

    errors.add(:columns, "must be a subset of #{COLUMNS.join(', ')}")
  end
end

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
#  team_id     :bigint           not null                (o primeiro grupo principal: onde a conversa entra)
#  team_ids               :bigint   default([]), not null, is an Array  (grupos principais)
#  fallback_team_ids      :bigint   default([]), not null, is an Array  (grupos secundários)
#  fallback_after_minutes :integer  (nulo = secundários entram na hora; com valor, esperam esses minutos)
#  channel_types          :string   default([]), not null, is an Array  (tipos de canal que entram)
#  inbox_ids              :bigint   default([]), not null, is an Array  (canais específicos que entram)
#  load_queue_keys        :string   default([]), not null, is an Array  (canais de trabalho que entram: chat, ticket…)
#  priority_mode          :string   default("chegada"), not null   (chegada | sla)
#
# Fila de encaminhamento (SPEC-15), no modelo do Zendesk: a conversa que chega é
# comparada com as filas em ordem e a primeira que casar entrega aos grupos
# principais dela; sem ninguém disponível neles, aos secundários. Quem dentro do
# grupo vai atender continua sendo decidido pelo status e pela carga do agente
# (SPEC-09 e SPEC-11).
class Staydesk::Queue < ApplicationRecord
  self.table_name = 'staydesk_queues'

  # Em que ordem a fila entrega quando há mais de um esperando. `chegada` é o
  # mais antigo primeiro; `sla` é quem está mais perto de vencer primeiro, e o
  # que não tem SLA vai depois, por chegada.
  PRIORITY_MODES = %w[chegada sla].freeze

  belongs_to :account
  belongs_to :team

  before_validation :alinhar_grupos

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :fallback_after_minutes, numericality: { greater_than: 0 }, allow_nil: true
  validates :priority_mode, inclusion: { in: PRIORITY_MODES }
  validate :conditions_shape
  validate :grupos_da_conta
  validate :secundario_nao_e_principal

  scope :ordered, -> { order(:position, :id) }
  scope :active, -> { where(active: true) }

  # A fila que responde por um grupo: a primeira em que ele é principal e, se não
  # houver, a primeira em que ele é secundário.
  def self.da_equipe(account_id, team_id)
    return if team_id.blank?

    filas = active.where(account_id: account_id).ordered.to_a
    filas.find { |fila| fila.team_ids.include?(team_id) } || filas.find { |fila| fila.fallback_team_ids.include?(team_id) }
  end

  # Quem está em qualquer um destes grupos, sem repetir.
  def self.membros(team_ids)
    return [] if team_ids.blank?

    TeamMember.where(team_id: team_ids).distinct.pluck(:user_id)
  end

  # A fila pega esta conversa? Pelo canal de trabalho ("Chat e WhatsApp"), pelo
  # tipo de canal ou pelo canal específico, que é como a operação pensa; as
  # condições avançadas afinam o resto. Tudo vazio é "todos", então fila sem
  # nada configurado recolhe o que sobrar.
  def atende_canal?(inbox)
    return false if inbox.blank?
    return true if canais_e_caixas_vazios?
    return true if inbox_ids.include?(inbox.id) || channel_types.include?(inbox.channel_type)

    load_queue_keys.any? && load_queue_keys.include?(Staydesk::LoadQueue.for_inbox(inbox)&.key)
  end

  def canais_e_caixas_vazios?
    channel_types.empty? && inbox_ids.empty? && load_queue_keys.empty?
  end

  # Os grupos principais, na ordem configurada.
  def teams
    por_id = account.teams.where(id: team_ids).index_by(&:id)
    team_ids.filter_map { |id| por_id[id] }
  end

  # Os grupos secundários: só entram quando nenhum principal tem gente disponível.
  def fallback_teams
    account.teams.where(id: fallback_team_ids)
  end

  private

  # O primeiro grupo principal é onde a conversa entra; `team_id` guarda isso e
  # atende quem só manda `team_id` pela API.
  def alinhar_grupos
    self.team_ids = [team_id] if team_ids.blank? && team_id.present?
    self.team_id = team_ids.first if team_ids.present?
  end

  def grupos_da_conta
    return errors.add(:team_ids, 'precisa de pelo menos um grupo principal') if team_ids.blank?
    return if account.blank?

    ids = team_ids + fallback_team_ids
    errors.add(:team_ids, 'tem grupo que não é desta conta') if (ids - account.teams.where(id: ids).ids).any?
  end

  def secundario_nao_e_principal
    errors.add(:fallback_team_ids, 'não pode repetir um grupo principal') if fallback_team_ids.intersect?(team_ids)
  end

  def conditions_shape
    return if conditions.is_a?(Array) && conditions.all? { |c| c.is_a?(Hash) && c['attribute_key'].present? && c['filter_operator'].present? }

    errors.add(:conditions, 'must be a list of { attribute_key, filter_operator, values, query_operator }')
  end
end

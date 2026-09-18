# == Schema Information
#
# Table name: staydesk_capacity_rules
#
#  id          :bigint           not null, primary key
#  account_id  :bigint           not null
#  name        :string           not null
#  description :string
#  limits      :jsonb            default({}), not null  ({"chat" => 4, "ticket" => 3}; ausente = sem limite)
#  is_default  :boolean          default(FALSE), not null (a regra de quem não tem regra)
#  user_ids    :bigint           default([]), not null, is an Array  (agentes com esta regra)
#  position    :integer          default(0), not null
#
# Regra de capacidade, como no Zendesk: quantas conversas de cada canal de
# trabalho o agente aguenta ao mesmo tempo. Uma regra é a padrão da conta; as
# outras são atribuídas a agentes, e cada agente tem no máximo uma. O status do
# agente diz o que ele recebe agora; a regra diz quanto.
class Staydesk::CapacityRule < ApplicationRecord
  self.table_name = 'staydesk_capacity_rules'

  belongs_to :account

  before_validation :normalize
  validates :name, presence: true, uniqueness: { scope: :account_id }
  validate :limits_must_be_whole_numbers
  validate :agents_belong_to_account
  after_save :unica_padrao, if: :is_default
  after_save :tirar_agentes_das_outras

  scope :ordered, -> { order(:position, :id) }

  # A regra que vale para o agente: a atribuída a ele ou a padrão da conta. Sem
  # nenhuma, não há teto.
  def self.for_user(account, user_id)
    by_user(account, [user_id])[user_id]
  end

  # As regras de vários agentes de uma vez, para a distribuição não consultar um por um.
  def self.by_user(account, user_ids)
    regras = where(account_id: account.id).ordered.to_a
    padrao = regras.find(&:is_default)
    user_ids.index_with { |id| regras.find { |regra| regra.user_ids.include?(id) } || padrao }
  end

  # Quantas conversas simultâneas deste canal; nil = sem limite.
  def limit_for(queue)
    limits[queue.to_s]&.to_i
  end

  def users
    account.users.where(id: user_ids)
  end

  private

  def normalize
    self.user_ids = user_ids.map(&:to_i).uniq
    self.limits = (limits || {}).slice(*filas_de_carga).filter_map do |queue, value|
      next if value.nil? || value.to_s.strip.empty?

      [queue.to_s, value.to_i]
    end.to_h
  end

  def filas_de_carga
    account ? Staydesk::LoadQueue.keys_for(account) : Staydesk::LoadQueue::DEFAULTS.pluck(:key)
  end

  def limits_must_be_whole_numbers
    return if limits.values.all? { |value| value.is_a?(Integer) && value >= 0 }

    errors.add(:limits, 'deve ter números inteiros a partir de zero')
  end

  def agents_belong_to_account
    return if account.blank? || user_ids.empty?

    errors.add(:user_ids, 'tem agente que não é desta conta') if (user_ids - account.users.where(id: user_ids).ids).any?
  end

  def unica_padrao
    self.class.where(account_id: account_id, is_default: true).where.not(id: id).find_each { |outra| outra.update!(is_default: false) }
  end

  # O agente tem uma regra só: entrar nesta tira das outras.
  def tirar_agentes_das_outras
    return if user_ids.empty?

    self.class.where(account_id: account_id).where.not(id: id).find_each do |outra|
      sobra = outra.user_ids - user_ids
      outra.update!(user_ids: sobra) if sobra.size != outra.user_ids.size
    end
  end
end

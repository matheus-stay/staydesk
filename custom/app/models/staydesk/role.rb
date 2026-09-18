# == Schema Information
#
# Table name: staydesk_roles
#
#  id          :bigint           not null, primary key
#  built_in    :boolean          default(FALSE), not null
#  description :string
#  name        :string           not null
#  permissions :string           default([]), not null, is an Array
#  position    :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Papel do agente com permissões granulares (SPEC-12). As permissões entram em
# AccountUser#permissions, que é o que o front usa para mostrar ou esconder, e o
# que a guarda do StayDesk usa para deixar passar ou barrar no servidor.
class Staydesk::Role < ApplicationRecord
  self.table_name = 'staydesk_roles'

  # O catálogo vive em custom/config/permissions.json: acrescentar uma permissão
  # é acrescentar uma linha lá, sem tocar em código. `report_manage` é chave do
  # próprio Chatwoot, que o front já entende; as demais são nossas.
  CATALOGO = Rails.root.join('custom/config/permissions.json').freeze

  def self.catalogo
    return JSON.parse(File.read(CATALOGO))['permissoes'] if Rails.env.development?

    @catalogo ||= JSON.parse(File.read(CATALOGO))['permissoes']
  end

  def self.permissions
    catalogo.pluck('chave')
  end

  # Quais permissões abrem uma área de configuração: a da própria área e a geral.
  def self.permissions_for_area(area)
    (catalogo.select { |item| item['area'] == area.to_s }.pluck('chave') + ['staydesk_settings_manage']).uniq
  end

  belongs_to :account
  has_many :account_user_roles, class_name: 'Staydesk::AccountUserRole', foreign_key: :staydesk_role_id,
                                dependent: :nullify, inverse_of: :staydesk_role

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validate :permissions_are_known

  scope :ordered, -> { order(:position, :id) }

  private

  def permissions_are_known
    desconhecidas = (permissions || []) - self.class.permissions
    errors.add(:permissions, "não conhece: #{desconhecidas.join(', ')}") if desconhecidas.any?
  end
end

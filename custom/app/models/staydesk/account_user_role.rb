# == Schema Information
#
# Table name: staydesk_account_user_roles
#
#  id              :bigint           not null, primary key
#  kind            :string           default("full"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_user_id :bigint           not null
#  staydesk_role_id :bigint          (nulo = sem papel granular)
#
# Papel StayDesk por cima do papel do Chatwoot. `light` é o agente leve: lê as
# conversas dos seus times e inboxes e só escreve nota privada.
class Staydesk::AccountUserRole < ApplicationRecord
  self.table_name = 'staydesk_account_user_roles'

  KINDS = %w[full light].freeze

  belongs_to :account_user
  belongs_to :staydesk_role, class_name: 'Staydesk::Role', optional: true

  validates :kind, inclusion: { in: KINDS }

  # As permissões que este vínculo concede: as do papel, mais a marca do agente leve.
  def permissions
    lista = staydesk_role&.permissions || []
    kind == 'light' ? (lista + ['staydesk_light']).uniq : lista
  end
end

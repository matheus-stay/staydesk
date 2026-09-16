# == Schema Information
#
# Table name: staydesk_account_user_roles
#
#  id              :bigint           not null, primary key
#  kind            :string           default("full"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_user_id :bigint           not null
#
# Papel StayDesk por cima do papel do Chatwoot. `light` é o agente leve: lê as
# conversas dos seus times e inboxes e só escreve nota privada.
class Staydesk::AccountUserRole < ApplicationRecord
  self.table_name = 'staydesk_account_user_roles'

  KINDS = %w[full light].freeze

  belongs_to :account_user

  validates :kind, inclusion: { in: KINDS }
end

# == Schema Information
#
# Table name: staydesk_impersonations
#
#  id         :bigint           not null, primary key
#  expires_at :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  actor_id   :bigint           not null
#  target_id  :bigint           not null
#
# Trilha de quem entrou como quem (SPEC-13). O acesso em si usa o token SSO de
# impersonação do próprio Chatwoot, que vale cinco minutos.
class Staydesk::Impersonation < ApplicationRecord
  self.table_name = 'staydesk_impersonations'

  belongs_to :account
  belongs_to :actor, class_name: 'User'
  belongs_to :target, class_name: 'User'

  scope :recent, -> { order(created_at: :desc) }
end

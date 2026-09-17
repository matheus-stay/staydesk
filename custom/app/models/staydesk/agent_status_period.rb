# == Schema Information
#
# Table name: staydesk_agent_status_periods
#
#  id              :bigint           not null, primary key
#  ended_at        :datetime         (nulo = status atual)
#  started_at      :datetime         not null
#  account_id      :bigint           not null
#  account_user_id :bigint           not null
#  agent_status_id :bigint           not null
#
# Um período em que o agente ficou num status; é o que o dashboard soma por dia.
class Staydesk::AgentStatusPeriod < ApplicationRecord
  self.table_name = 'staydesk_agent_status_periods'

  belongs_to :account
  belongs_to :account_user
  belongs_to :agent_status, class_name: 'Staydesk::AgentStatus'

  scope :current, -> { where(ended_at: nil) }
end

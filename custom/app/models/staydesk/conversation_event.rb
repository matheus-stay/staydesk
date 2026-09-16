# == Schema Information
#
# Table name: staydesk_conversation_events
#
#  id              :bigint           not null, primary key
#  from_value      :string
#  kind            :string           not null
#  to_value        :string
#  created_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  user_id         :bigint
#
# Mudanças de status, responsável, time e prioridade por conversa, gravadas por
# Custom::Conversation. É o que o dashboard lê para reabertura e linha do tempo.
class Staydesk::ConversationEvent < ApplicationRecord
  self.table_name = 'staydesk_conversation_events'

  KINDS = %w[status_changed assignee_changed team_changed priority_changed].freeze
  TRACKED = { 'status' => 'status_changed', 'assignee_id' => 'assignee_changed',
              'team_id' => 'team_changed', 'priority' => 'priority_changed' }.freeze

  belongs_to :account
  belongs_to :conversation

  validates :kind, inclusion: { in: KINDS }
end

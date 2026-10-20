# Escolhe a primeira política ativa cujas condições batem com a conversa, reaproveitando
# o avaliador de condições das automações do Chatwoot.
class Staydesk::Sla::PolicyMatcher
  # Condição própria do StayDesk: os valores são tipos de canal ("Channel::Email")
  # e ids de caixa. Vira `inbox_id` na hora de avaliar, para que a caixa criada
  # depois da política entre sozinha no SLA do canal dela.
  CHANNEL_CONDITION = 'staydesk_channel'.freeze

  # O avaliador espera um objeto com a cara de AutomationRule.
  RuleShim = Struct.new(:id, :account, :account_id, :conditions, :event_name, keyword_init: true) do
    def authorization_error!; end
  end

  def initialize(conversation)
    @conversation = conversation
  end

  def perform
    Staydesk::SlaPolicy.active.where(account_id: @conversation.account_id).ordered.find do |policy|
      matches?(policy)
    end
  end

  private

  def matches?(policy)
    return true if policy.conditions.blank?

    shim = RuleShim.new(id: policy.id, account: policy.account, account_id: policy.account_id,
                        conditions: policy.conditions.map { |condition| resolve(condition) }, event_name: 'conversation_updated')
    ::AutomationRules::ConditionsFilterService.new(shim, @conversation, {}).perform.present?
  end

  def resolve(condition)
    return condition unless condition['attribute_key'] == CHANNEL_CONDITION

    condition.merge('attribute_key' => 'inbox_id', 'values' => inbox_ids(Array(condition['values'])))
  end

  # Nenhuma caixa do canal ainda: um id que não existe, para a condição não casar.
  def inbox_ids(values)
    types, ids = values.partition { |value| value.to_s.start_with?('Channel::') }
    ids = ids.map(&:to_i) + Inbox.where(account_id: @conversation.account_id, channel_type: types).pluck(:id)
    ids.presence || [0]
  end
end

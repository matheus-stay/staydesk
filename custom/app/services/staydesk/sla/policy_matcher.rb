# Escolhe a primeira política ativa cujas condições batem com a conversa, reaproveitando
# o avaliador de condições das automações do Chatwoot.
class Staydesk::Sla::PolicyMatcher
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
                        conditions: policy.conditions, event_name: 'conversation_updated')
    ::AutomationRules::ConditionsFilterService.new(shim, @conversation, {}).perform.present?
  end
end

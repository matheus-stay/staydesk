# Os eventos de SLA disparam regras de automação. AutomationRuleListener não tem gancho,
# então esta subclasse expõe os três eventos e reaproveita o processamento dele.
class Staydesk::SlaAutomationListener < AutomationRuleListener
  def staydesk_sla_warning(event)
    process_conversation_event(event, 'staydesk_sla_warning')
  end

  def staydesk_sla_breached(event)
    process_conversation_event(event, 'staydesk_sla_breached')
  end

  def staydesk_sla_met(event)
    process_conversation_event(event, 'staydesk_sla_met')
  end
end

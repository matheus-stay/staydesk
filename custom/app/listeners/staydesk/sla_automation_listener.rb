# Os eventos de SLA disparam regras de automação. AutomationRuleListener não tem
# gancho, então esta subclasse expõe os três eventos de SLA e reaproveita o
# processamento dele.
#
# O que ela NÃO pode fazer é responder aos eventos do produto: inscrita no
# despachante ao lado do ouvinte original, cada `conversation_created` seria
# processado duas vezes e toda automação agiria em dobro — foi assim que o
# cliente recebeu dois avisos de "recebemos o seu chamado" para o mesmo ticket.
# Por isso os eventos herdados são removidos, inclusive os que o produto vier a
# acrescentar amanhã.
class Staydesk::SlaAutomationListener < AutomationRuleListener
  EVENTOS = %i[staydesk_sla_warning staydesk_sla_breached staydesk_sla_met].freeze

  (AutomationRuleListener.public_instance_methods(false) - EVENTOS).each do |evento_do_produto|
    undef_method(evento_do_produto)
  end

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

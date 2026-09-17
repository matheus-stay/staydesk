// Eventos de SLA nas regras de automação do Chatwoot. Entram em
// settings/automation/constants.js por dois ganchos de uma linha.
export const STAYDESK_AUTOMATION_EVENTS = [
  { key: 'staydesk_sla_warning', value: 'STAYDESK_SLA_WARNING' },
  { key: 'staydesk_sla_breached', value: 'STAYDESK_SLA_BREACHED' },
  { key: 'staydesk_sla_met', value: 'STAYDESK_SLA_MET' },
];

// As mesmas condições e ações de "conversa atualizada": a regra escolhe
// caixa, prioridade, time, labels e atributos, e age como qualquer outra.
export const staydeskAutomationEvents = automations =>
  Object.fromEntries(
    STAYDESK_AUTOMATION_EVENTS.map(event => [
      event.key,
      automations.conversation_updated,
    ])
  );

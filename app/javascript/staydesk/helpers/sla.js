// Selo de SLA a partir dos atributos que o dashboard grava na conversa:
// sla_status (running | warning | breached | paused | none), sla_vence_em (ISO 8601), sla_alvo.
export const SLA_STATUSES = ['running', 'warning', 'breached', 'paused'];

const MINUTE = 60 * 1000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

// Formato curto, como no Zendesk: 45m, 2h, 3d; negativo quando venceu.
export const formatDuration = ms => {
  const abs = Math.abs(ms);
  const sign = ms < 0 ? '-' : '';
  if (abs >= DAY) return `${sign}${Math.floor(abs / DAY)}d`;
  if (abs >= HOUR) return `${sign}${Math.floor(abs / HOUR)}h`;
  return `${sign}${Math.max(1, Math.floor(abs / MINUTE))}m`;
};

export const slaState = (attributes = {}, now = Date.now()) => {
  const status = attributes.sla_status;
  if (!SLA_STATUSES.includes(status)) return null;
  if (status === 'paused') return { status, label: null };

  const dueAt = attributes.sla_vence_em
    ? new Date(attributes.sla_vence_em).getTime()
    : null;
  const remaining = dueAt === null ? null : dueAt - now;
  const breached =
    status === 'breached' || (remaining !== null && remaining < 0);
  return {
    status: breached ? 'breached' : status,
    label: remaining === null ? null : formatDuration(remaining),
  };
};

// Estado de uma métrica do SLA aplicado (primeira resposta, próxima resposta,
// resolução). Responder depois do prazo não apaga o atraso: o painel dizia
// "cumprido" enquanto o selo da conversa dizia "vencido", e quem lia os dois
// não sabia em qual acreditar. Vencido ganha de cumprido.
export const metricState = metric => {
  if (!metric) return 'none';
  if (metric.breached) return metric.met_at ? 'late' : 'breached';
  if (metric.met_at) return 'met';
  return metric.due_at ? 'due' : 'none';
};

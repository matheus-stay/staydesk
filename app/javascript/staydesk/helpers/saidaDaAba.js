import AgentStatusesAPI from '../api/agentStatuses';

// Fechou a aba, saiu do status: o agente só volta a receber quando escolher um
// status de novo. O aviso vai ao fechar e também no F5; quem decide é o
// servidor, que confere depois se ainda sobrou alguma aba conectada.
export const avisarSaidaDaAba = () => {
  window.addEventListener('pagehide', () => {
    if (!window.location.pathname.includes('/app/accounts/')) return;
    if (!window.axios?.defaults?.headers?.common?.['access-token']) return;
    AgentStatusesAPI.leave().catch(() => {});
  });
};

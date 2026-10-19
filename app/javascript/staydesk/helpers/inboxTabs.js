// Quem atende cada canal sai das filas: os grupos da fila atendem os canais que
// ela pega (Staydesk::QueueMembership). A aba "Colaboradores" da caixa do
// Chatwoot seria desfeita a cada minuto, então sai da tela.
// Entra em settings/inbox/Settings.vue por um gancho de uma linha.
export const semColaboradores = tabs =>
  tabs.filter(tab => tab.key !== 'collaborators');

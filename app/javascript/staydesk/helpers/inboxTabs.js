// Todo agente atende todos os canais (Staydesk::ChannelMembership), então a aba
// "Colaboradores" da caixa do Chatwoot não tem o que configurar e sai da tela.
// Entra em settings/inbox/Settings.vue por um gancho de uma linha.
export const semColaboradores = tabs =>
  tabs.filter(tab => tab.key !== 'collaborators');

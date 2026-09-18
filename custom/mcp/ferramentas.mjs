// O catálogo de ferramentas do MCP é uma tabela: cada linha vira uma ferramenta.
// Acrescentar um endpoint da API é acrescentar uma linha, não escrever código.
//
// `corpoEm` diz sob qual chave a API espera o corpo (o Rails usa strong params),
// e `argumentos` descreve o que o modelo pode mandar.

const TEXTO = { type: 'string' };
const NUMERO = { type: 'number' };
const BOOLEANO = { type: 'boolean' };
const LISTA = { type: 'array', items: {} };
const OBJETO = { type: 'object', additionalProperties: true };

const listar = (nome, rota, descricao) => ({
  nome: `staydesk_${nome}_listar`,
  descricao,
  metodo: 'GET',
  rota,
  argumentos: {},
});

const criar = (nome, rota, chave, descricao, propriedades) => ({
  nome: `staydesk_${nome}_criar`,
  descricao,
  metodo: 'POST',
  rota,
  corpoEm: chave,
  argumentos: propriedades,
});

const atualizar = (nome, rota, chave, descricao, propriedades) => ({
  nome: `staydesk_${nome}_atualizar`,
  descricao,
  metodo: 'PATCH',
  rota: `${rota}/{id}`,
  corpoEm: chave,
  argumentos: { id: NUMERO, ...propriedades },
});

export const FERRAMENTAS = [
  {
    nome: 'staydesk_kpis',
    descricao:
      'Números da operação no período: CSAT, tempos de primeira resposta e resolução por fila, quem espera na fila e o tempo de cada agente em cada status.',
    metodo: 'GET',
    rota: 'staydesk/kpis',
    argumentos: {
      since: { ...TEXTO, description: 'início do período em ISO 8601' },
      until: { ...TEXTO, description: 'fim do período em ISO 8601' },
    },
  },
  listar('filas', 'staydesk/queues', 'Filas de encaminhamento: para qual grupo cada demanda vai, transbordo e aceite.'),
  criar('filas', 'staydesk/queues', 'queue', 'Cria uma fila de encaminhamento.', {
    name: TEXTO,
    description: TEXTO,
    team_id: NUMERO,
    fallback_team_ids: LISTA,
    fallback_mode: { ...TEXTO, enum: ['sempre', 'quando_faltar'] },
    fallback_after_minutes: NUMERO,
    accept_required: BOOLEANO,
    accept_timeout_seconds: NUMERO,
    conditions: LISTA,
  }),
  atualizar('filas', 'staydesk/queues', 'queue', 'Altera uma fila de encaminhamento.', {
    name: TEXTO,
    description: TEXTO,
    team_id: NUMERO,
    fallback_team_ids: LISTA,
    fallback_mode: { ...TEXTO, enum: ['sempre', 'quando_faltar'] },
    fallback_after_minutes: NUMERO,
    accept_required: BOOLEANO,
    accept_timeout_seconds: NUMERO,
    conditions: LISTA,
    active: BOOLEANO,
  }),
  listar('filas_de_carga', 'staydesk/load_queues', 'Filas de carga: que canal e que caixa contam como chat e como ticket.'),
  atualizar('filas_de_carga', 'staydesk/load_queues', 'load_queue', 'Altera uma fila de carga.', {
    name: TEXTO,
    channel_types: LISTA,
    inbox_ids: LISTA,
    catch_all: BOOLEANO,
  }),
  listar('status_do_ticket', 'staydesk/ticket_statuses', 'Catálogo de status do ticket da conta.'),
  criar('status_do_ticket', 'staydesk/ticket_statuses', 'ticket_status', 'Cria um status de ticket.', {
    name: TEXTO,
    description: TEXTO,
    color: TEXTO,
    base_status: { ...TEXTO, enum: ['open', 'pending', 'snoozed', 'resolved'] },
    default_for_base: BOOLEANO,
    apply_on_assign: BOOLEANO,
  }),
  atualizar('status_do_ticket', 'staydesk/ticket_statuses', 'ticket_status', 'Altera um status de ticket.', {
    name: TEXTO,
    description: TEXTO,
    color: TEXTO,
    base_status: TEXTO,
    default_for_base: BOOLEANO,
    apply_on_assign: BOOLEANO,
    active: BOOLEANO,
  }),
  listar('status_do_agente', 'staydesk/agent_statuses', 'Status de disponibilidade do agente e a carga de cada um.'),
  criar('status_do_agente', 'staydesk/agent_statuses', 'agent_status', 'Cria um status de agente.', {
    name: TEXTO,
    color: TEXTO,
    availability: { ...TEXTO, enum: ['online', 'busy'] },
    capacity: OBJETO,
    inbox_ids: LISTA,
  }),
  atualizar('status_do_agente', 'staydesk/agent_statuses', 'agent_status', 'Altera um status de agente.', {
    name: TEXTO,
    color: TEXTO,
    availability: TEXTO,
    capacity: OBJETO,
    inbox_ids: LISTA,
    active: BOOLEANO,
  }),
  {
    nome: 'staydesk_carga_dos_agentes',
    descricao: 'Quantas conversas cada agente atende agora em cada fila, contra o limite do status dele.',
    metodo: 'GET',
    rota: 'staydesk/agent_loads',
    argumentos: {},
  },
  listar('politicas_de_sla', 'staydesk/sla_policies', 'Políticas de SLA: alvos por prioridade, pausa e aviso.'),
  criar('politicas_de_sla', 'staydesk/sla_policies', 'sla_policy', 'Cria uma política de SLA.', {
    name: TEXTO,
    description: TEXTO,
    targets: OBJETO,
    conditions: LISTA,
    pause_statuses: LISTA,
    warning_ratio: NUMERO,
    calendar_id: NUMERO,
  }),
  listar('calendarios', 'staydesk/calendars', 'Calendários de horário comercial e feriados.'),
  listar('visualizacoes', 'staydesk/team_views', 'Visualizações por time: o que cada grupo vê na fila.'),
  listar('papeis', 'staydesk/roles', 'Papéis com permissões granulares e o catálogo de permissões disponível.'),
  criar('papeis', 'staydesk/roles', 'role', 'Cria um papel de agente.', {
    name: TEXTO,
    description: TEXTO,
    permissions: LISTA,
  }),
  {
    nome: 'staydesk_area_de_trabalho',
    descricao: 'Área de trabalho resolvida para quem chama: menus, colunas da lista, campos e painéis da conversa.',
    metodo: 'GET',
    rota: 'staydesk/workspace',
    argumentos: {},
  },
  {
    nome: 'staydesk_aceitacao_dos_agentes',
    descricao: 'Aceitação de chat e WhatsApp por agente: quantos convites recebeu, aceitou, recusou e deixou expirar.',
    metodo: 'GET',
    rota: 'staydesk/offer_stats',
    argumentos: { since: TEXTO, until: TEXTO },
  },
  {
    nome: 'staydesk_eventos_das_conversas',
    descricao: 'Linha do tempo das conversas: mudanças de status, de responsável, de grupo e de prioridade.',
    metodo: 'GET',
    rota: 'staydesk/events',
    argumentos: { since: TEXTO, until: TEXTO, limit: NUMERO },
  },
  {
    nome: 'staydesk_slas_aplicados',
    descricao: 'SLA aplicado a cada conversa, com alvo, status e quando vence.',
    metodo: 'GET',
    rota: 'staydesk/applied_slas',
    argumentos: { since: TEXTO, until: TEXTO, limit: NUMERO },
  },
  {
    nome: 'staydesk_conversas',
    descricao: 'Conversas da conta, com os filtros da API do Chatwoot (status, inbox_id, team_id, assignee_type, page).',
    metodo: 'GET',
    rota: 'conversations',
    argumentos: {
      status: TEXTO,
      inbox_id: NUMERO,
      team_id: NUMERO,
      assignee_type: TEXTO,
      page: NUMERO,
    },
  },
  listar('tokens_de_api', 'staydesk/api_tokens', 'Tokens de API da conta, com os escopos de cada um e o catálogo de escopos possíveis.'),
  criar('tokens_de_api', 'staydesk/api_tokens', 'api_token', 'Cria um token de API com escopo próprio. O valor em claro volta uma única vez nesta resposta.', {
    name: TEXTO,
    description: TEXTO,
    scopes: LISTA,
    user_id: NUMERO,
    expires_at: TEXTO,
  }),
  atualizar('tokens_de_api', 'staydesk/api_tokens', 'api_token', 'Suspende ou reativa um token de API.', {
    active: BOOLEANO,
    scopes: LISTA,
    name: TEXTO,
  }),
  listar('times', 'teams', 'Grupos da conta.'),
  listar('caixas', 'inboxes', 'Caixas de entrada da conta, com o tipo de canal de cada uma.'),
  listar('agentes', 'agents', 'Agentes da conta e o papel de cada um.'),
];

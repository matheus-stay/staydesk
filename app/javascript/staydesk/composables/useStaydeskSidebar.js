import { computed, h, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { AREA, CONFIGURA } from '../routes';
import { estaNaCentral } from '../helpers/central';
import { useTeamViews } from './useTeamViews';
import { useWorkspace } from './useWorkspace';
import { useCentralStore } from '../store/central';

const colorDot = color =>
  h('span', {
    class: 'inline-block rounded-full size-2',
    style: { backgroundColor: color || 'currentColor' },
  });

// Itens que a camada StayDesk acrescenta à barra lateral do upstream
// (Sidebar.vue os recebe por spread, em dois ganchos de uma linha).
export const useStaydeskSidebar = () => {
  const { t } = useI18n();
  const { accountScopedRoute } = useAccount();
  const { views, ensureLoaded, pollCounts, countFor } = useTeamViews();
  const workspace = useWorkspace();
  const route = useRoute();
  const { checkPermissions } = usePolicy();
  const central = useCentralStore();

  // Dentro da central de administração a barra é a navegação da central, como no
  // Zendesk: quem está configurando precisa do menu de configuração, não do de
  // atendimento. Fora dela, vale a área de trabalho de quem atende.
  const naCentral = computed(() => estaNaCentral(route.path));
  // O Sidebar pergunta duas vezes: a lista principal (que tem Conversation) e a
  // de "Mais". Na central, a principal vira só Configurações e a outra fica vazia.
  const filterMenuNames = names => {
    if (!naCentral.value) return workspace.filterMenuNames(names);

    return names.includes('Conversation') ? ['Settings'] : [];
  };

  onMounted(async () => {
    await Promise.all([ensureLoaded(), workspace.ensureLoaded()]);
    pollCounts();
  });

  const viewsItems = computed(() => {
    if (!views.value.length) return [];
    return [
      {
        name: 'StaydeskHubHome',
        label: t('STAYDESK.HUB.HOME'),
        icon: 'i-lucide-house',
        activeOn: ['staydesk_hub_home'],
        to: accountScopedRoute('staydesk_hub_home'),
      },
      {
        name: 'StaydeskTeamViews',
        label: t('STAYDESK.TEAM_VIEWS.SIDEBAR'),
        icon: 'i-lucide-layout-list',
        activeOn: ['staydesk_view_conversation'],
        collapsible: false,
        staydeskNoScroll: true,
        showTreeLine: true,
        children: views.value.map(view => ({
          name: `staydesk-view-${view.id}`,
          label: view.name,
          icon: colorDot(view.color),
          badgeCount: countFor(view.id),
          to: accountScopedRoute('staydesk_view_conversations', {
            id: view.id,
          }),
        })),
      },
    ];
  });

  // Relatórios passam a morar na central de administração, junto do resto que se
  // configura; a barra de atendimento fica só com as visualizações.
  const reportsEntry = () => ({
    name: 'StaydeskReports',
    permissions: ['administrator', 'report_manage', 'staydesk_report_own'],
    label: t('SIDEBAR.REPORTS'),
    icon: 'i-lucide-chart-spline',
    activeOn: [
      'account_overview_reports',
      'conversation_reports',
      'csat_reports',
    ],
    to: accountScopedRoute('account_overview_reports'),
  });

  // Cada entrada só aparece para quem tem a permissão da área, o mesmo desenho
  // que as rotas e as policies usam. Relatórios seguem a permissão do produto.
  const podeVer = item =>
    !item.permissions || checkPermissions(item.permissions);

  // A Central organizada por assunto, como a central de administração do Zendesk.
  // Cada seção é um subgrupo; o que não estiver mapeado cai em "Outros", para
  // nenhuma tela do produto sumir quando o upstream acrescentar uma.
  const SECOES = [
    {
      // Na ordem em que o trabalho chega a quem atende, como o encaminhamento
      // omnichannel do Zendesk: o que é chat e ticket, para quais grupos vai,
      // quanto cada agente aguenta e o que cada status recebe.
      name: 'CentralDistribuicao',
      label: () => t('STAYDESK.CENTRAL.SECTIONS.DISTRIBUTION'),
      icon: 'i-lucide-route',
      itens: [
        'StaydeskLoadQueuesSettings',
        'StaydeskQueuesSettings',
        'StaydeskCapacityRulesSettings',
        'StaydeskAgentStatusesSettings',
        'Settings Agent Assignment',
      ],
    },
    {
      name: 'CentralAtendimento',
      label: () => t('STAYDESK.CENTRAL.SECTIONS.WORK'),
      icon: 'i-lucide-headset',
      itens: [
        'StaydeskTicketStatusesSettings',
        'StaydeskTeamViewsSettings',
        'StaydeskWorkspaceSettings',
      ],
    },
    {
      name: 'CentralPrazos',
      label: () => t('STAYDESK.CENTRAL.SECTIONS.SERVICE_LEVEL'),
      icon: 'i-lucide-timer',
      itens: ['StaydeskSlaSettings', 'StaydeskCalendarsSettings'],
    },
    {
      name: 'CentralPessoas',
      label: () => t('STAYDESK.CENTRAL.SECTIONS.PEOPLE'),
      icon: 'i-lucide-users',
      itens: [
        'Settings Agents',
        'Settings Teams',
        'StaydeskAgentRolesSettings',
        'StaydeskApiTokensSettings',
        'Settings Custom Roles',
      ],
    },
    {
      name: 'CentralCanais',
      label: () => t('STAYDESK.CENTRAL.SECTIONS.CHANNELS'),
      icon: 'i-lucide-inbox',
      itens: ['StaydeskChannelsSettings', 'Settings Templates'],
    },
    {
      name: 'CentralRegras',
      label: () => t('STAYDESK.CENTRAL.SECTIONS.RULES'),
      icon: 'i-lucide-workflow',
      itens: [
        'Settings Automation',
        'Settings Macros',
        'Settings Canned Responses',
        'Settings Agent Bots',
        'Settings Labels',
        'Settings Custom Attributes',
      ],
    },
    {
      name: 'CentralConta',
      label: () => t('STAYDESK.CENTRAL.SECTIONS.ACCOUNT'),
      icon: 'i-lucide-building-2',
      itens: [
        'Settings Account Settings',
        'StaydeskApiDocs',
        'Settings Integrations',
        'Settings Data',
        'Settings Audit Logs',
        'Settings Security',
        'Settings Billing',
      ],
    },
  ];

  // Fora de seção, no topo: a home e os relatórios.
  const SOLTOS = ['StaydeskCentralHome', 'StaydeskReports'];

  // Telas do produto que não fazem sentido na Central: o SLA do Chatwoot é
  // Enterprise, e o nosso motor de SLA já mora em Prazos; a lista de caixas do
  // produto dá lugar à de canais, agrupada por tipo.
  const FORA_DA_CENTRAL = ['Settings Sla', 'Settings Inboxes'];

  const organizarCentral = itens => {
    const aceitos = itens.filter(item => !FORA_DA_CENTRAL.includes(item.name));
    const porNome = new Map(aceitos.map(item => [item.name, item]));
    const usados = new Set();
    const pega = nome => {
      const item = porNome.get(nome);
      if (item) usados.add(nome);
      return item;
    };

    const topo = SOLTOS.map(pega).filter(Boolean);
    // Cada seção é um dropdown com home própria: o nome abre a home, a seta
    // recolhe. A chave da rota é o nome da seção sem o prefixo.
    const secoes = SECOES.map(secao => ({
      name: secao.name,
      chave: secao.name.replace(/^Central/, '').toLowerCase(),
      label: secao.label(),
      icon: secao.icon,
      collapsible: true,
      to: accountScopedRoute('staydesk_central_section', {
        secao: secao.name.replace(/^Central/, '').toLowerCase(),
      }),
      children: secao.itens.map(pega).filter(Boolean),
    })).filter(secao => secao.children.length);

    const sobrou = aceitos.filter(item => !usados.has(item.name));
    const outros = sobrou.length
      ? [
          {
            name: 'CentralOutros',
            chave: 'outros',
            label: t('STAYDESK.CENTRAL.SECTIONS.OTHER'),
            icon: 'i-lucide-ellipsis',
            collapsible: true,
            to: accountScopedRoute('staydesk_central_section', {
              secao: 'outros',
            }),
            children: sobrou,
          },
        ]
      : [];

    const resultado = [...topo, ...secoes, ...outros];
    // As páginas da Central leem o mesmo mapa que a barra montou.
    central.registrar(resultado.filter(item => item.children));
    return resultado;
  };

  const centralHomeEntry = () => ({
    name: 'StaydeskCentralHome',
    label: t('STAYDESK.CENTRAL.HOME'),
    icon: 'i-lucide-house',
    activeOn: ['staydesk_central_home'],
    to: accountScopedRoute('staydesk_central_home'),
  });

  const settingsItems = computed(() => [
    centralHomeEntry(),
    reportsEntry(),
    {
      name: 'StaydeskTeamViewsSettings',
      permissions: AREA.VIEWS,
      label: t('STAYDESK.TEAM_VIEWS.SETTINGS_TITLE'),
      icon: 'i-lucide-layout-list',
      activeOn: ['staydesk_team_views_settings'],
      to: accountScopedRoute('staydesk_team_views_settings'),
    },
    {
      name: 'StaydeskWorkspaceSettings',
      permissions: AREA.VIEWS,
      label: t('STAYDESK.WORKSPACE.SETTINGS_TITLE'),
      icon: 'i-lucide-layout-dashboard',
      activeOn: ['staydesk_workspace_settings'],
      to: accountScopedRoute('staydesk_workspace_settings'),
    },
    {
      name: 'StaydeskApiDocs',
      label: t('STAYDESK.API_DOCS.TITLE'),
      icon: 'i-lucide-code-xml',
      activeOn: ['staydesk_api_docs'],
      to: accountScopedRoute('staydesk_api_docs'),
    },
    {
      name: 'StaydeskApiTokensSettings',
      permissions: AREA.ROLES,
      label: t('STAYDESK.API_TOKENS.SETTINGS_TITLE'),
      icon: 'i-lucide-key-round',
      activeOn: ['staydesk_api_tokens_settings'],
      to: accountScopedRoute('staydesk_api_tokens_settings'),
    },
    {
      name: 'StaydeskAgentRolesSettings',
      permissions: AREA.ROLES,
      label: t('STAYDESK.AGENT_ROLES.SETTINGS_TITLE'),
      icon: 'i-lucide-user-round-cog',
      activeOn: ['staydesk_agent_roles_settings'],
      to: accountScopedRoute('staydesk_agent_roles_settings'),
    },
    {
      name: 'StaydeskQueuesSettings',
      permissions: AREA.QUEUES,
      label: t('STAYDESK.QUEUES.SETTINGS_TITLE'),
      icon: 'i-lucide-list-ordered',
      activeOn: ['staydesk_queues_settings'],
      to: accountScopedRoute('staydesk_queues_settings'),
    },
    {
      name: 'StaydeskLoadQueuesSettings',
      permissions: AREA.QUEUES,
      label: t('STAYDESK.LOAD_QUEUES.SETTINGS_TITLE'),
      icon: 'i-lucide-split',
      activeOn: ['staydesk_load_queues_settings'],
      to: accountScopedRoute('staydesk_load_queues_settings'),
    },
    {
      name: 'StaydeskChannelsSettings',
      permissions: CONFIGURA,
      label: t('STAYDESK.CHANNELS.SETTINGS_TITLE'),
      icon: 'i-lucide-inbox',
      activeOn: [
        'staydesk_channels_settings',
        'settings_inbox_list',
        'settings_inbox_new',
        'settings_inbox_show',
        'settings_inbox_finish',
        'settings_inboxes_page_channel',
        'settings_inboxes_add_agents',
      ],
      to: accountScopedRoute('staydesk_channels_settings'),
    },
    {
      name: 'StaydeskCapacityRulesSettings',
      permissions: AREA.QUEUES,
      label: t('STAYDESK.CAPACITY_RULES.SETTINGS_TITLE'),
      icon: 'i-lucide-gauge',
      activeOn: ['staydesk_capacity_rules_settings'],
      to: accountScopedRoute('staydesk_capacity_rules_settings'),
    },
    {
      name: 'StaydeskSlaSettings',
      permissions: AREA.SLA,
      label: t('STAYDESK.SLA.SETTINGS_TITLE'),
      icon: 'i-lucide-timer',
      activeOn: ['staydesk_sla_settings'],
      to: accountScopedRoute('staydesk_sla_settings'),
    },
    {
      name: 'StaydeskCalendarsSettings',
      permissions: AREA.SLA,
      label: t('STAYDESK.CALENDARS.SETTINGS_TITLE'),
      icon: 'i-lucide-calendar-days',
      activeOn: ['staydesk_calendars_settings'],
      to: accountScopedRoute('staydesk_calendars_settings'),
    },
    {
      name: 'StaydeskAgentStatusesSettings',
      permissions: AREA.STATUSES,
      label: t('STAYDESK.AGENT_STATUS.SETTINGS_TITLE'),
      icon: 'i-lucide-user-round-check',
      activeOn: ['staydesk_agent_statuses_settings'],
      to: accountScopedRoute('staydesk_agent_statuses_settings'),
    },
    {
      name: 'StaydeskTicketStatusesSettings',
      permissions: AREA.STATUSES,
      label: t('STAYDESK.TICKET_STATUS.SETTINGS_TITLE'),
      icon: 'i-lucide-tags',
      activeOn: ['staydesk_ticket_statuses_settings'],
      to: accountScopedRoute('staydesk_ticket_statuses_settings'),
    },
  ]);

  // Dentro de Conversas, o que o usuário vê: quem entra pelas visualizações não
  // precisa da lista geral nem dos canais (SPEC-03).
  const filterConversationMenu = items => {
    const permitidos = workspace.config.value?.conversation_menu;
    if (!Array.isArray(permitidos)) return items;
    // A home do Hub é do Hub: fica, seja qual for o menu da área de trabalho.
    return items.filter(
      item => item.name === 'StaydeskHubHome' || permitidos.includes(item.name)
    );
  };

  return {
    viewsItems,
    filterConversationMenu,
    organizarCentral,
    settingsItems: computed(() => settingsItems.value.filter(podeVer)),
    filterMenuNames,
  };
};

import { computed, h, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { AREA } from '../routes';
import { estaNaCentral } from '../helpers/central';
import { useTeamViews } from './useTeamViews';
import { useWorkspace } from './useWorkspace';

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
      name: 'CentralAtendimento',
      label: () => t('STAYDESK.CENTRAL.SECTIONS.WORK'),
      icon: 'i-lucide-headset',
      itens: [
        'StaydeskQueuesSettings',
        'StaydeskTeamViewsSettings',
        'StaydeskWorkspaceSettings',
        'Settings Agent Assignment',
      ],
    },
    {
      name: 'CentralPrazos',
      label: () => t('STAYDESK.CENTRAL.SECTIONS.SERVICE_LEVEL'),
      icon: 'i-lucide-timer',
      itens: [
        'StaydeskTicketStatusesSettings',
        'StaydeskAgentStatusesSettings',
        'StaydeskSlaSettings',
        'StaydeskCalendarsSettings',
        'Settings Sla',
      ],
    },
    {
      name: 'CentralPessoas',
      label: () => t('STAYDESK.CENTRAL.SECTIONS.PEOPLE'),
      icon: 'i-lucide-users',
      itens: [
        'Settings Agents',
        'Settings Teams',
        'StaydeskAgentRolesSettings',
        'Settings Custom Roles',
      ],
    },
    {
      name: 'CentralCanais',
      label: () => t('STAYDESK.CENTRAL.SECTIONS.CHANNELS'),
      icon: 'i-lucide-inbox',
      itens: ['Settings Inboxes', 'Settings Templates'],
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

  const organizarCentral = itens => {
    const porNome = new Map(itens.map(item => [item.name, item]));
    const usados = new Set();
    const pega = nome => {
      const item = porNome.get(nome);
      if (item) usados.add(nome);
      return item;
    };

    const topo = SOLTOS.map(pega).filter(Boolean);
    const secoes = SECOES.map(secao => ({
      name: secao.name,
      label: secao.label(),
      icon: secao.icon,
      children: secao.itens.map(pega).filter(Boolean),
    })).filter(secao => secao.children.length);

    const sobrou = itens.filter(item => !usados.has(item.name));
    const outros = sobrou.length
      ? [
          {
            name: 'CentralOutros',
            label: t('STAYDESK.CENTRAL.SECTIONS.OTHER'),
            icon: 'i-lucide-ellipsis',
            children: sobrou,
          },
        ]
      : [];

    return [...topo, ...secoes, ...outros];
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
    return items.filter(item => permitidos.includes(item.name));
  };

  return {
    viewsItems,
    filterConversationMenu,
    organizarCentral,
    settingsItems: computed(() => settingsItems.value.filter(podeVer)),
    filterMenuNames,
  };
};

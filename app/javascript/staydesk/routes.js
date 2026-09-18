import { frontendURL } from 'dashboard/helper/URLHelper';
import ConversationView from 'dashboard/routes/dashboard/conversation/ConversationView.vue';
import SettingsWrapper from 'dashboard/routes/dashboard/settings/SettingsWrapper.vue';
import CentralHome from './pages/CentralHome.vue';
import ApiDocs from './pages/ApiDocs.vue';
import CentralSection from './pages/CentralSection.vue';
import HubHome from './pages/HubHome.vue';
import WideSettingsWrapper from './layouts/WideSettingsWrapper.vue';
import ApiTokensSettings from './pages/ApiTokensSettings.vue';
import TeamViewsSettings from './pages/TeamViewsSettings.vue';
import WorkspaceSettings from './pages/WorkspaceSettings.vue';
import AgentRolesSettings from './pages/AgentRolesSettings.vue';
import SlaSettings from './pages/SlaSettings.vue';
import CalendarsSettings from './pages/CalendarsSettings.vue';
import AgentStatusesSettings from './pages/AgentStatusesSettings.vue';
import TicketStatusesSettings from './pages/TicketStatusesSettings.vue';
import QueuesSettings from './pages/QueuesSettings.vue';
import LoadQueuesSettings from './pages/LoadQueuesSettings.vue';
import CapacityRulesSettings from './pages/CapacityRulesSettings.vue';
import ChannelsSettings from './pages/ChannelsSettings.vue';
import KpisPage from './pages/KpisPage.vue';
import { teamViewFolderId } from './store/teamViews';

// Quem abre cada área da central: o administrador, quem tem a permissão geral de
// configurar, ou quem tem a permissão daquela área. O mesmo desenho vale no
// servidor, nas policies (Staydesk::AreaDeConfiguracao), então esconder aqui não
// é a única barreira. O catálogo de permissões fica em custom/config/permissions.json.
export const CONFIGURA = ['administrator', 'staydesk_settings_manage'];
// Quem vê os números: o mesmo critério dos relatórios do produto.
export const RELATORIOS = [
  'administrator',
  'report_manage',
  'staydesk_report_own',
];
export const AREA = {
  VIEWS: [...CONFIGURA, 'staydesk_views_manage'],
  ROLES: [...CONFIGURA, 'staydesk_roles_manage'],
  SLA: [...CONFIGURA, 'staydesk_sla_manage'],
  STATUSES: [...CONFIGURA, 'staydesk_statuses_manage'],
  QUEUES: [...CONFIGURA, 'staydesk_queues_manage'],
};

const CONVERSATION_PERMISSIONS = [
  'administrator',
  'agent',
  'conversation_manage',
  'conversation_unassigned_manage',
  'conversation_participating_manage',
];

// Rotas da camada StayDesk. Entram como filhas da rota da conta (o AppContainer
// com a barra lateral) por withStaydeskRoutes, chamada em dashboard/routes/index.js.
const routes = [
  {
    path: frontendURL('accounts/:accountId/staydesk/hub'),
    name: 'staydesk_hub_home',
    meta: { permissions: CONVERSATION_PERMISSIONS },
    component: HubHome,
  },
  {
    path: frontendURL('accounts/:accountId/staydesk/views/:id'),
    name: 'staydesk_view_conversations',
    meta: { permissions: CONVERSATION_PERMISSIONS },
    component: ConversationView,
    props: route => ({ foldersId: teamViewFolderId(route.params.id) }),
  },
  {
    path: frontendURL(
      'accounts/:accountId/staydesk/views/:id/conversations/:conversation_id'
    ),
    name: 'staydesk_view_conversation',
    meta: { permissions: CONVERSATION_PERMISSIONS },
    component: ConversationView,
    props: route => ({
      conversationId: route.params.conversation_id,
      foldersId: teamViewFolderId(route.params.id),
    }),
  },
  {
    path: frontendURL('accounts/:accountId/settings/staydesk/central'),
    component: SettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_central_home',
        component: CentralHome,
        meta: { permissions: CONFIGURA },
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/settings/staydesk/central/:secao'),
    component: WideSettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_central_section',
        component: CentralSection,
        meta: { permissions: CONVERSATION_PERMISSIONS },
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/settings/staydesk/api-docs'),
    component: WideSettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_api_docs',
        component: ApiDocs,
        meta: { permissions: CONVERSATION_PERMISSIONS },
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/settings/staydesk/api-tokens'),
    component: SettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_api_tokens_settings',
        component: ApiTokensSettings,
        meta: { permissions: AREA.ROLES },
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/settings/staydesk/team-views'),
    component: SettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_team_views_settings',
        component: TeamViewsSettings,
        meta: { permissions: AREA.VIEWS },
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/settings/staydesk/workspace'),
    component: SettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_workspace_settings',
        component: WorkspaceSettings,
        meta: { permissions: AREA.VIEWS },
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/settings/staydesk/agent-roles'),
    component: SettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_agent_roles_settings',
        component: AgentRolesSettings,
        meta: { permissions: AREA.ROLES },
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/settings/staydesk/sla'),
    component: SettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_sla_settings',
        component: SlaSettings,
        meta: { permissions: AREA.SLA },
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/settings/staydesk/calendars'),
    component: SettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_calendars_settings',
        component: CalendarsSettings,
        meta: { permissions: AREA.SLA },
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/settings/staydesk/agent-statuses'),
    component: SettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_agent_statuses_settings',
        component: AgentStatusesSettings,
        meta: { permissions: AREA.STATUSES },
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/settings/staydesk/ticket-statuses'),
    component: SettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_ticket_statuses_settings',
        component: TicketStatusesSettings,
        meta: { permissions: AREA.STATUSES },
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/settings/staydesk/load-queues'),
    component: SettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_load_queues_settings',
        component: LoadQueuesSettings,
        meta: { permissions: AREA.QUEUES },
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/settings/staydesk/kpis'),
    component: WideSettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_kpis',
        component: KpisPage,
        meta: { permissions: RELATORIOS },
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/settings/staydesk/channels'),
    component: SettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_channels_settings',
        component: ChannelsSettings,
        meta: { permissions: CONFIGURA },
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/settings/staydesk/capacity-rules'),
    component: SettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_capacity_rules_settings',
        component: CapacityRulesSettings,
        meta: { permissions: AREA.QUEUES },
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/settings/staydesk/queues'),
    component: SettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_queues_settings',
        component: QueuesSettings,
        meta: { permissions: AREA.QUEUES },
      },
    ],
  },
];

const ACCOUNT_ROOT = frontendURL('accounts/:accountId');

export const withStaydeskRoutes = dashboardRoutes => {
  const accountRoute = dashboardRoutes.find(
    route => route.path === ACCOUNT_ROOT
  );
  accountRoute.children.push(...routes);
  return dashboardRoutes;
};

export default routes;

import { frontendURL } from 'dashboard/helper/URLHelper';
import ConversationView from 'dashboard/routes/dashboard/conversation/ConversationView.vue';
import SettingsWrapper from 'dashboard/routes/dashboard/settings/SettingsWrapper.vue';
import TeamViewsSettings from './pages/TeamViewsSettings.vue';
import WorkspaceSettings from './pages/WorkspaceSettings.vue';
import { teamViewFolderId } from './store/teamViews';

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
    path: frontendURL('accounts/:accountId/settings/staydesk/team-views'),
    component: SettingsWrapper,
    children: [
      {
        path: '',
        name: 'staydesk_team_views_settings',
        component: TeamViewsSettings,
        meta: { permissions: ['administrator'] },
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
        meta: { permissions: ['administrator'] },
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

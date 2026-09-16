import { computed, h, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
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
        collapsible: true,
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

  const settingsItems = computed(() => [
    {
      name: 'StaydeskTeamViewsSettings',
      label: t('STAYDESK.TEAM_VIEWS.SETTINGS_TITLE'),
      icon: 'i-lucide-layout-list',
      activeOn: ['staydesk_team_views_settings'],
      to: accountScopedRoute('staydesk_team_views_settings'),
    },
    {
      name: 'StaydeskWorkspaceSettings',
      label: t('STAYDESK.WORKSPACE.SETTINGS_TITLE'),
      icon: 'i-lucide-layout-dashboard',
      activeOn: ['staydesk_workspace_settings'],
      to: accountScopedRoute('staydesk_workspace_settings'),
    },
  ]);

  return {
    viewsItems,
    settingsItems,
    filterMenuNames: workspace.filterMenuNames,
  };
};

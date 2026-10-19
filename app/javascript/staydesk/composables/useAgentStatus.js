import { computed, h, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAgentStatusStore } from '../store/agentStatus';

const PREFIX = 'staydesk:';
const OFFLINE = `${PREFIX}offline`;
const DEFAULT_COLORS = {
  online: '#1a9f63',
  busy: '#d97706',
  offline: '#8b8d98',
};
// A bolinha do gatilho do menu usa classe Tailwind, como no upstream.
const DOT_CLASSES = {
  online: 'bg-n-teal-9',
  busy: 'bg-n-amber-9',
  offline: 'bg-n-slate-9',
};

// O menu de disponibilidade do agente com os status da conta. Entra no
// SidebarProfileMenuStatus.vue por dois ganchos de uma linha: a lista e a troca.
export const useAgentStatus = () => {
  const { t } = useI18n();
  const store = useAgentStatusStore();
  const vuex = useStore();
  const currentAccountId = useMapGetter('getCurrentAccountId');

  onMounted(() => {
    if (!store.uiFlags.hasFetched) store.fetch();
  });

  const hasStatuses = computed(() => store.active.length > 0);

  const icone = color =>
    h('span', {
      class: 'size-[12px] rounded',
      style: { backgroundColor: color },
    });

  // Sem status escolhido o agente está offline, e é isso que o menu mostra.
  // Antes ele exibia o primeiro status como ativo, e quem reabria o StayDesk
  // parecia disponível sem ter escolhido nada.
  const menuItems = computed(() => [
    ...store.active.map(status => ({
      label: status.name,
      value: `${PREFIX}${status.id}`,
      color: DOT_CLASSES[status.availability],
      icon: icone(status.color || DEFAULT_COLORS[status.availability]),
      active: status.id === store.currentStatusId,
    })),
    {
      label: t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.OFFLINE'),
      value: OFFLINE,
      color: DOT_CLASSES.offline,
      icon: icone(DEFAULT_COLORS.offline),
      active: !store.currentStatusId,
    },
  ]);

  const change = async id => {
    const { availability } =
      id === OFFLINE ? await store.goOffline() : await store.changeMine(id);
    await vuex.dispatch('updateAvailability', {
      availability,
      account_id: currentAccountId.value,
    });
  };

  // Decide na hora se o valor é nosso (o upstream segue com os dele quando não é)
  // e troca em segundo plano.
  const handle = value => {
    if (typeof value !== 'string' || !value.startsWith(PREFIX)) return false;
    change(value === OFFLINE ? OFFLINE : Number(value.slice(PREFIX.length)));
    return true;
  };

  return {
    hasStatuses,
    menuItems,
    handle,
    current: computed(() => store.current),
  };
};

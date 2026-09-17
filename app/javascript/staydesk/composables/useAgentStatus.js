import { computed, h, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAgentStatusStore } from '../store/agentStatus';

const PREFIX = 'staydesk:';
const DEFAULT_COLORS = { online: '#1a9f63', busy: '#d97706' };
// A bolinha do gatilho do menu usa classe Tailwind, como no upstream.
const DOT_CLASSES = { online: 'bg-n-teal-9', busy: 'bg-n-amber-9' };

// O menu de disponibilidade do agente com os status da conta. Entra no
// SidebarProfileMenuStatus.vue por dois ganchos de uma linha: a lista e a troca.
export const useAgentStatus = () => {
  const store = useAgentStatusStore();
  const vuex = useStore();
  const currentAccountId = useMapGetter('getCurrentAccountId');
  const currentAvailability = useMapGetter('getCurrentUserAvailability');

  onMounted(() => {
    if (!store.uiFlags.hasFetched) store.fetch();
  });

  const hasStatuses = computed(() => store.active.length > 0);

  // Enquanto o agente não escolheu, o item ativo é o que casa com a
  // disponibilidade atual do Chatwoot (ou o primeiro): o menu do upstream
  // precisa de um item ativo para desenhar o gatilho.
  const activeId = computed(() => {
    if (store.currentStatusId) return store.currentStatusId;
    const match =
      store.active.find(
        status => status.availability === currentAvailability.value
      ) || store.active[0];
    return match?.id ?? null;
  });

  const menuItems = computed(() =>
    store.active.map(status => {
      const color = status.color || DEFAULT_COLORS[status.availability];
      return {
        label: status.name,
        value: `${PREFIX}${status.id}`,
        color: DOT_CLASSES[status.availability],
        icon: h('span', {
          class: 'size-[12px] rounded',
          style: { backgroundColor: color },
        }),
        active: status.id === activeId.value,
      };
    })
  );

  const change = async id => {
    const { availability } = await store.changeMine(id);
    await vuex.dispatch('updateAvailability', {
      availability,
      account_id: currentAccountId.value,
    });
  };

  // Decide na hora se o valor é nosso (o upstream segue com os dele quando não é)
  // e troca em segundo plano.
  const handle = value => {
    if (typeof value !== 'string' || !value.startsWith(PREFIX)) return false;
    change(Number(value.slice(PREFIX.length)));
    return true;
  };

  return {
    hasStatuses,
    menuItems,
    handle,
    current: computed(() => store.current),
  };
};

import { createPinia, setActivePinia } from 'pinia';
import { useAgentStatusStore } from '../../store/agentStatus';
import { useAgentStatus } from '../useAgentStatus';

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: vi.fn() }),
  useMapGetter: () => ({ value: 1 }),
}));

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: () => 'Offline' }) }));

describe('useAgentStatus', () => {
  beforeEach(() => setActivePinia(createPinia()));

  const seed = () => {
    const store = useAgentStatusStore();
    store.statuses = [
      {
        id: 1,
        name: 'Só chat',
        availability: 'online',
        active: true,
        inbox_ids: [],
      },
      {
        id: 2,
        name: 'Ausente',
        availability: 'busy',
        active: true,
        inbox_ids: [],
      },
      {
        id: 3,
        name: 'Antigo',
        availability: 'online',
        active: false,
        inbox_ids: [],
      },
    ];
    store.uiFlags.hasFetched = true;
    return store;
  };

  // Quem reabre o StayDesk sem status escolhido está offline, e o menu diz
  // isso; antes ele exibia um status como ativo sem ninguém ter escolhido.
  it('shows Offline as the active item until the agent picks a status', () => {
    seed();
    const { hasStatuses, menuItems } = useAgentStatus();

    expect(hasStatuses.value).toBe(true);
    expect(menuItems.value.map(item => item.label)).toEqual([
      'Só chat',
      'Ausente',
      'Offline',
    ]);
    expect(menuItems.value.filter(item => item.active)).toHaveLength(1);
    expect(menuItems.value.find(item => item.active).value).toBe(
      'staydesk:offline'
    );
  });

  it('prefers the status the agent chose', () => {
    const store = seed();
    store.currentStatusId = 1;

    expect(
      useAgentStatus().menuItems.value.find(item => item.active).value
    ).toBe('staydesk:1');
  });

  it('only handles its own values', () => {
    seed();
    const { handle } = useAgentStatus();

    expect(handle('online')).toBe(false);
  });

  it('goes offline through its own endpoint', () => {
    const store = seed();
    store.goOffline = vi.fn().mockResolvedValue({ availability: 'offline' });
    const { handle } = useAgentStatus();

    expect(handle('staydesk:offline')).toBe(true);
    expect(store.goOffline).toHaveBeenCalled();
  });
});

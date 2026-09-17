import { createPinia, setActivePinia } from 'pinia';
import { useAgentStatusStore } from '../../store/agentStatus';
import { useAgentStatus } from '../useAgentStatus';

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: vi.fn() }),
  useMapGetter: name => ({
    value: name === 'getCurrentUserAvailability' ? 'busy' : 1,
  }),
}));

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

  it('always marks one item as active so the upstream menu can render', () => {
    seed();
    const { hasStatuses, menuItems } = useAgentStatus();

    expect(hasStatuses.value).toBe(true);
    expect(menuItems.value.map(item => item.label)).toEqual([
      'Só chat',
      'Ausente',
    ]);
    expect(menuItems.value.find(item => item.active).label).toBe('Ausente');
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
});

import { createPinia, setActivePinia } from 'pinia';
import TeamViewsAPI from '../../api/teamViews';
import {
  parseTeamViewFolderId,
  teamViewFolderId,
  useTeamViewsStore,
} from '../teamViews';

vi.mock('../../api/teamViews', () => ({
  default: {
    get: vi.fn(),
    counts: vi.fn(),
    create: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
  },
}));

const views = [
  {
    id: 2,
    name: 'Pendentes',
    position: 1,
    color: '#f00',
    query: { payload: [] },
  },
  { id: 1, name: 'Fila', position: 0, color: '#0f0', query: { payload: [] } },
];

describe('useTeamViewsStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
  });

  it('fetches and orders the views by position', async () => {
    TeamViewsAPI.get.mockResolvedValue({ data: views });
    const store = useTeamViewsStore();

    await store.fetch();

    expect(store.ordered.map(view => view.name)).toEqual(['Fila', 'Pendentes']);
    expect(store.uiFlags.hasFetched).toBe(true);
  });

  it('exposes a view as a folder the chat list understands', async () => {
    TeamViewsAPI.get.mockResolvedValue({ data: views });
    const store = useTeamViewsStore();
    await store.fetch();

    const folder = store.asFolder(teamViewFolderId(1));

    expect(folder).toMatchObject({
      id: 'staydesk-1',
      name: 'Fila',
      staydeskTeamView: true,
    });
    expect(store.asFolder(7)).toBeUndefined();
  });

  it('keeps counts per view', async () => {
    TeamViewsAPI.counts.mockResolvedValue({ data: { counts: { 1: 4 } } });
    const store = useTeamViewsStore();

    await store.fetchCounts();

    expect(store.countFor(1)).toBe(4);
    expect(store.countFor(2)).toBe(0);
  });

  it('updates and removes records in place', async () => {
    TeamViewsAPI.get.mockResolvedValue({ data: views });
    TeamViewsAPI.update.mockResolvedValue({
      data: { ...views[1], name: 'Fila nova' },
    });
    TeamViewsAPI.delete.mockResolvedValue({});
    const store = useTeamViewsStore();
    await store.fetch();

    await store.update(1, { name: 'Fila nova' });
    await store.remove(2);

    expect(store.records).toEqual([{ ...views[1], name: 'Fila nova' }]);
  });
});

describe('team view folder ids', () => {
  it('round-trips the prefixed id', () => {
    expect(parseTeamViewFolderId(teamViewFolderId(12))).toBe(12);
    expect(parseTeamViewFolderId('3')).toBeNull();
    expect(parseTeamViewFolderId(undefined)).toBeNull();
  });
});

import { createPinia, setActivePinia } from 'pinia';
import TeamViewsAPI from '../../api/teamViews';
import { useTeamViews } from '../useTeamViews';

vi.mock('../../api/teamViews', () => ({
  default: { get: vi.fn(), counts: vi.fn() },
}));

describe('useTeamViews', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
    TeamViewsAPI.get.mockResolvedValue({
      data: [
        {
          id: 1,
          name: 'Fila',
          position: 0,
          query: {
            payload: [{ attribute_key: 'assignee_id', values: ['me'] }],
          },
        },
      ],
    });
  });

  it('loads the views once', async () => {
    const { views, ensureLoaded } = useTeamViews();

    await ensureLoaded();
    await ensureLoaded();

    expect(TeamViewsAPI.get).toHaveBeenCalledTimes(1);
    expect(views.value.map(view => view.name)).toEqual(['Fila']);
  });

  it('exposes a team view as a folder', async () => {
    const { ensureLoaded, asFolder } = useTeamViews();
    await ensureLoaded();

    const folder = asFolder('staydesk-1', 7);

    expect(folder).toMatchObject({ name: 'Fila', staydeskTeamView: true });
    expect(folder.query.payload[0].values).toEqual([7]);
    expect(asFolder('1', 7)).toBeUndefined();
  });

  // O filtro de conversas do produto não conhece o canal de trabalho: a lista
  // usa a consulta que o servidor já resolveu, senão a fila vinha vazia com o
  // número ao lado dizendo que havia conversa.
  it('uses the query the server already resolved', async () => {
    TeamViewsAPI.get.mockResolvedValue({
      data: [
        {
          id: 2,
          name: 'Fila - Chat',
          position: 0,
          query: {
            payload: [
              { attribute_key: 'staydesk_load_queue', values: ['chat'] },
            ],
          },
          resolved_query: {
            payload: [{ attribute_key: 'inbox_id', values: [1, 3] }],
          },
        },
      ],
    });
    const { ensureLoaded, asFolder } = useTeamViews();
    await ensureLoaded();

    expect(asFolder('staydesk-2', 7).query.payload).toEqual([
      { attribute_key: 'inbox_id', values: [1, 3] },
    ]);
  });
});

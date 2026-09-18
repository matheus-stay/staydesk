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
});

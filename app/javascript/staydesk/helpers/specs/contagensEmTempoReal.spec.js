import { createPinia, setActivePinia } from 'pinia';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import TeamViewsAPI from '../../api/teamViews';
import { useTeamViewsStore } from '../../store/teamViews';
import {
  atualizarContagensEmTempoReal,
  ESPERA_MS,
} from '../contagensEmTempoReal';

vi.mock('../../api/teamViews', () => ({
  default: { get: vi.fn(), counts: vi.fn() },
}));

const storeFalsa = () => {
  const ouvintes = [];
  return {
    subscribe: fn => {
      ouvintes.push(fn);
      return () => ouvintes.splice(ouvintes.indexOf(fn), 1);
    },
    commit: type => ouvintes.forEach(fn => fn({ type })),
  };
};

describe('atualizarContagensEmTempoReal', () => {
  let pinia;
  let parar;

  beforeEach(() => {
    vi.useFakeTimers();
    pinia = createPinia();
    setActivePinia(pinia);
    TeamViewsAPI.counts.mockResolvedValue({ data: { counts: { 1: 2 } } });
    useTeamViewsStore(pinia).uiFlags.hasFetched = true;
  });

  afterEach(() => {
    parar?.();
    vi.useRealTimers();
    vi.clearAllMocks();
  });

  it('asks for the counts again when a conversation changes, once per burst', async () => {
    const store = storeFalsa();
    parar = atualizarContagensEmTempoReal({ store, pinia });

    store.commit('ADD_CONVERSATION');
    store.commit('ASSIGN_AGENT');
    store.commit('CHANGE_CONVERSATION_STATUS');
    await vi.advanceTimersByTimeAsync(ESPERA_MS);

    expect(TeamViewsAPI.counts).toHaveBeenCalledTimes(1);
    expect(useTeamViewsStore(pinia).counts).toEqual({ 1: 2 });
  });

  it('ignores changes that do not move a conversation between views', async () => {
    const store = storeFalsa();
    parar = atualizarContagensEmTempoReal({ store, pinia });

    store.commit('SET_CURRENT_CHAT_WINDOW');
    await vi.advanceTimersByTimeAsync(ESPERA_MS);

    expect(TeamViewsAPI.counts).not.toHaveBeenCalled();
  });

  it('catches up after the websocket reconnects', async () => {
    parar = atualizarContagensEmTempoReal({ store: storeFalsa(), pinia });

    emitter.emit(BUS_EVENTS.WEBSOCKET_RECONNECT);
    await vi.advanceTimersByTimeAsync(ESPERA_MS);

    expect(TeamViewsAPI.counts).toHaveBeenCalledTimes(1);
  });
});

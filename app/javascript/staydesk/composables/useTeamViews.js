import { computed, onScopeDispose } from 'vue';
import { useIntervalFn } from '@vueuse/core';
import { resolveCurrentAgent } from '../helpers/teamViewQuery';
import { useTeamViewsStore } from '../store/teamViews';

// Rede de segurança: a contagem também é pedida a cada mudança de conversa que
// chega em tempo real (helpers/contagensEmTempoReal.js).
const COUNTS_INTERVAL = 30 * 1000;

export const useTeamViews = () => {
  const store = useTeamViewsStore();

  const views = computed(() => store.ordered);
  const counts = computed(() => store.counts);

  const ensureLoaded = async () => {
    if (store.uiFlags.hasFetched || store.uiFlags.isFetching) return;
    await store.fetch();
  };

  const pollCounts = () => {
    const { pause } = useIntervalFn(
      () => store.fetchCounts(),
      COUNTS_INTERVAL,
      {
        immediateCallback: true,
      }
    );
    onScopeDispose(pause);
  };

  return {
    views,
    counts,
    ensureLoaded,
    pollCounts,
    // A pasta que a lista recebe vai com a consulta que o servidor já resolveu
    // (canal de trabalho em caixas, "o próprio agente" no id de quem olha): o
    // filtro de conversas do produto não conhece os marcadores da camada.
    asFolder: (foldersId, currentUserId) => {
      const folder = store.asFolder(foldersId);
      if (!folder) return folder;

      const query = folder.resolved_query || folder.query;
      return {
        ...folder,
        query: {
          ...query,
          payload: resolveCurrentAgent(query?.payload, currentUserId),
        },
      };
    },
    countFor: store.countFor,
  };
};

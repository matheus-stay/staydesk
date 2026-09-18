import { computed, onScopeDispose } from 'vue';
import { useIntervalFn } from '@vueuse/core';
import { resolveCurrentAgent } from '../helpers/teamViewQuery';
import { useTeamViewsStore } from '../store/teamViews';

const COUNTS_INTERVAL = 60 * 1000;

export const useTeamViews = () => {
  const store = useTeamViewsStore();

  const views = computed(() => store.ordered);
  const counts = computed(() => store.counts);

  const ensureLoaded = async () => {
    if (store.uiFlags.hasFetched || store.uiFlags.isFetching) return;
    await store.fetch();
  };

  // Contadores das views no ritmo do cache do servidor (30 s) sem martelar a API.
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
    // A pasta que a lista recebe já vai com o responsável resolvido: o marcador
    // "o próprio agente" vira o id de quem está olhando, antes de a consulta sair.
    asFolder: (foldersId, currentUserId) => {
      const folder = store.asFolder(foldersId);
      if (!folder) return folder;

      return {
        ...folder,
        query: {
          ...folder.query,
          payload: resolveCurrentAgent(folder.query?.payload, currentUserId),
        },
      };
    },
    countFor: store.countFor,
  };
};

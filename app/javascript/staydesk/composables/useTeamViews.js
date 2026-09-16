import { computed, onScopeDispose } from 'vue';
import { useIntervalFn } from '@vueuse/core';
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
    asFolder: store.asFolder,
    countFor: store.countFor,
  };
};

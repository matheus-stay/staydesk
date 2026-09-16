import { defineStore } from 'pinia';
import WorkspaceAPI from '../api/workspace';

// Até a resposta chegar, nada é escondido: as listas ausentes significam "tudo".
const EMPTY = {
  menu: null,
  list: { layout: 'cards', columns: [], sort_by: null, page_size: 25 },
  conversation: { fields: null, panels: null, apps: null },
  macros: { mode: 'all', ids: [] },
  composer: { submit_as: true, after_send: 'stay' },
  role: null,
  team_ids: [],
};

export const useWorkspaceStore = defineStore('staydeskWorkspace', {
  state: () => ({
    config: EMPTY,
    uiFlags: { isFetching: false, hasFetched: false },
  }),

  actions: {
    async fetch() {
      if (this.uiFlags.isFetching) return;
      this.uiFlags.isFetching = true;
      try {
        const { data } = await WorkspaceAPI.resolved();
        this.config = { ...EMPTY, ...data };
        this.uiFlags.hasFetched = true;
      } finally {
        this.uiFlags.isFetching = false;
      }
    },
  },
});

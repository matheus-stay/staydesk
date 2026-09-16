import { defineStore } from 'pinia';
import TeamViewsAPI from '../api/teamViews';

export const TEAM_VIEW_FOLDER_PREFIX = 'staydesk-';

// Id usado nas rotas e no ChatList para distinguir uma view por time de uma pasta pessoal.
export const teamViewFolderId = id => `${TEAM_VIEW_FOLDER_PREFIX}${id}`;

export const parseTeamViewFolderId = foldersId => {
  const value = String(foldersId ?? '');
  if (!value.startsWith(TEAM_VIEW_FOLDER_PREFIX)) return null;
  return Number(value.slice(TEAM_VIEW_FOLDER_PREFIX.length));
};

export const useTeamViewsStore = defineStore('staydeskTeamViews', {
  state: () => ({
    records: [],
    counts: {},
    uiFlags: { isFetching: false, isSaving: false, hasFetched: false },
  }),

  getters: {
    ordered: state =>
      [...state.records].sort((a, b) => a.position - b.position || a.id - b.id),
    byId: state => id => state.records.find(view => view.id === Number(id)),
    countFor: state => id => state.counts[id] ?? 0,
    // A view no formato que o ChatList espera de uma pasta (custom view).
    asFolder() {
      return foldersId => {
        const view = this.byId(parseTeamViewFolderId(foldersId));
        if (!view) return undefined;
        return { ...view, id: foldersId, staydeskTeamView: true };
      };
    },
  },

  actions: {
    async fetch() {
      this.uiFlags.isFetching = true;
      try {
        const { data } = await TeamViewsAPI.get();
        this.records = data;
        this.uiFlags.hasFetched = true;
      } finally {
        this.uiFlags.isFetching = false;
      }
    },

    async fetchCounts() {
      const { data } = await TeamViewsAPI.counts();
      this.counts = data.counts;
    },

    async create(payload) {
      this.uiFlags.isSaving = true;
      try {
        const { data } = await TeamViewsAPI.create(payload);
        this.records.push(data);
        return data;
      } finally {
        this.uiFlags.isSaving = false;
      }
    },

    async update(id, payload) {
      this.uiFlags.isSaving = true;
      try {
        const { data } = await TeamViewsAPI.update(id, payload);
        this.records = this.records.map(view => (view.id === id ? data : view));
        return data;
      } finally {
        this.uiFlags.isSaving = false;
      }
    },

    async remove(id) {
      await TeamViewsAPI.delete(id);
      this.records = this.records.filter(view => view.id !== id);
    },
  },
});

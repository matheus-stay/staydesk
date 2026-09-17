import { defineStore } from 'pinia';
import AgentStatusesAPI from '../api/agentStatuses';

export const useAgentStatusStore = defineStore('staydeskAgentStatus', {
  state: () => ({
    statuses: [],
    currentStatusId: null,
    uiFlags: { isFetching: false, hasFetched: false, isSaving: false },
  }),

  getters: {
    active: state => state.statuses.filter(status => status.active),
    current: state =>
      state.statuses.find(status => status.id === state.currentStatusId) ||
      null,
  },

  actions: {
    async fetch() {
      this.uiFlags.isFetching = true;
      try {
        const { data } = await AgentStatusesAPI.list();
        this.statuses = data.statuses;
        this.currentStatusId = data.current_status_id;
        this.uiFlags.hasFetched = true;
      } finally {
        this.uiFlags.isFetching = false;
      }
    },

    async changeMine(id) {
      const { data } = await AgentStatusesAPI.changeMine(id);
      this.currentStatusId = data.current_status_id;
      return data;
    },

    async save(id, payload) {
      this.uiFlags.isSaving = true;
      try {
        const { data } = id
          ? await AgentStatusesAPI.update(id, payload)
          : await AgentStatusesAPI.create(payload);
        this.statuses = id
          ? this.statuses.map(status => (status.id === id ? data : status))
          : [...this.statuses, data];
        return data;
      } finally {
        this.uiFlags.isSaving = false;
      }
    },

    async remove(id) {
      await AgentStatusesAPI.delete(id);
      this.statuses = this.statuses.filter(status => status.id !== id);
    },
  },
});

import { defineStore } from 'pinia';
import AgentStatusesAPI from '../api/agentStatuses';

export const useAgentStatusStore = defineStore('staydeskAgentStatus', {
  state: () => ({
    statuses: [],
    currentStatusId: null,
    loads: [],
    loadQueues: [],
    offerStats: [],
    uiFlags: {
      isFetching: false,
      hasFetched: false,
      isSaving: false,
      isFetchingLoads: false,
    },
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

    // As filas de carga da conta: é delas que saem os campos de limite.
    async fetchLoadQueues() {
      const { data } = await AgentStatusesAPI.loadQueues();
      this.loadQueues = data.load_queues || [];
    },

    // Painel de carga: quantas conversas cada agente atende agora em cada fila.
    async fetchLoads() {
      this.uiFlags.isFetchingLoads = true;
      try {
        const { data } = await AgentStatusesAPI.loads();
        this.loads = data;
      } finally {
        this.uiFlags.isFetchingLoads = false;
      }
    },

    // Aceitação de convites por agente, o indicador da coordenação.
    async fetchOfferStats() {
      const { data } = await AgentStatusesAPI.offerStats();
      this.offerStats = data;
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

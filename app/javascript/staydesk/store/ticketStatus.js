import { defineStore } from 'pinia';
import TicketStatusesAPI from '../api/ticketStatuses';

export const ATTRIBUTE_KEY = 'staydesk_status';

export const useTicketStatusStore = defineStore('staydeskTicketStatus', {
  state: () => ({
    statuses: [],
    uiFlags: { isFetching: false, hasFetched: false, isSaving: false },
  }),

  getters: {
    active: state => state.statuses.filter(status => status.active),
    enabled() {
      return this.active.length > 0;
    },
    byName: state => name =>
      state.statuses.find(status => status.name === name) || null,
  },

  actions: {
    async fetch() {
      this.uiFlags.isFetching = true;
      try {
        const { data } = await TicketStatusesAPI.list();
        this.statuses = data;
        this.uiFlags.hasFetched = true;
      } finally {
        this.uiFlags.isFetching = false;
      }
    },

    async ensureLoaded() {
      if (!this.uiFlags.hasFetched && !this.uiFlags.isFetching) {
        await this.fetch();
      }
    },

    // O status personalizado de uma conversa: o atributo, ou o padrão do status base.
    forConversation(conversation) {
      if (!conversation) return null;
      const named = this.byName(
        conversation.custom_attributes?.[ATTRIBUTE_KEY]
      );
      if (named) return named;
      const base = this.active.filter(
        status => status.base_status === conversation.status
      );
      return base.find(status => status.default_for_base) || base[0] || null;
    },

    async apply(conversationId, ticketStatusId, snoozedUntil = null) {
      const { data } = await TicketStatusesAPI.apply(
        conversationId,
        ticketStatusId,
        snoozedUntil
      );
      return data;
    },

    async save(id, payload) {
      this.uiFlags.isSaving = true;
      try {
        const { data } = id
          ? await TicketStatusesAPI.update(id, payload)
          : await TicketStatusesAPI.create(payload);
        this.statuses = id
          ? this.statuses.map(status => (status.id === id ? data : status))
          : [...this.statuses, data];
        return data;
      } finally {
        this.uiFlags.isSaving = false;
      }
    },

    async remove(id) {
      await TicketStatusesAPI.delete(id);
      this.statuses = this.statuses.filter(status => status.id !== id);
    },

    async reorder(ids) {
      const { data } = await TicketStatusesAPI.reorder(ids);
      this.statuses = data;
    },
  },
});

import { defineStore } from 'pinia';
import SlaAPI from '../api/sla';

export const useSlaStore = defineStore('staydeskSla', {
  state: () => ({
    policies: [],
    calendars: [],
    uiFlags: { isFetching: false, isSaving: false },
  }),

  actions: {
    async fetch() {
      this.uiFlags.isFetching = true;
      try {
        const [policies, calendars] = await Promise.all([
          SlaAPI.policies(),
          SlaAPI.calendars(),
        ]);
        this.policies = policies.data;
        this.calendars = calendars.data;
      } finally {
        this.uiFlags.isFetching = false;
      }
    },

    async savePolicy(id, data) {
      this.uiFlags.isSaving = true;
      try {
        const { data: saved } = id
          ? await SlaAPI.updatePolicy(id, data)
          : await SlaAPI.createPolicy(data);
        this.policies = id
          ? this.policies.map(policy => (policy.id === id ? saved : policy))
          : [...this.policies, saved];
        return saved;
      } finally {
        this.uiFlags.isSaving = false;
      }
    },

    async removePolicy(id) {
      await SlaAPI.deletePolicy(id);
      this.policies = this.policies.filter(policy => policy.id !== id);
    },

    async reorderPolicies(ids) {
      const { data } = await SlaAPI.reorderPolicies(ids);
      this.policies = data;
    },

    async saveCalendar(id, data) {
      this.uiFlags.isSaving = true;
      try {
        const { data: saved } = id
          ? await SlaAPI.updateCalendar(id, data)
          : await SlaAPI.createCalendar(data);
        this.calendars = id
          ? this.calendars.map(calendar =>
              calendar.id === id ? saved : calendar
            )
          : [...this.calendars, saved];
        return saved;
      } finally {
        this.uiFlags.isSaving = false;
      }
    },

    async removeCalendar(id) {
      await SlaAPI.deleteCalendar(id);
      this.calendars = this.calendars.filter(calendar => calendar.id !== id);
    },
  },
});

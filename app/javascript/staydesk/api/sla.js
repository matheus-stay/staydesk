/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

// /api/v1/accounts/:accountId/staydesk/{sla_policies,calendars,conversations/:id/sla}
class SlaAPI extends ApiClient {
  constructor() {
    super('staydesk', { accountScoped: true });
  }

  policies() {
    return axios.get(`${this.url}/sla_policies`);
  }

  createPolicy(data) {
    return axios.post(`${this.url}/sla_policies`, { sla_policy: data });
  }

  updatePolicy(id, data) {
    return axios.patch(`${this.url}/sla_policies/${id}`, { sla_policy: data });
  }

  deletePolicy(id) {
    return axios.delete(`${this.url}/sla_policies/${id}`);
  }

  reorderPolicies(ids) {
    return axios.put(`${this.url}/sla_policies/reorder`, { ids });
  }

  calendars() {
    return axios.get(`${this.url}/calendars`);
  }

  createCalendar(data) {
    return axios.post(`${this.url}/calendars`, { calendar: data });
  }

  updateCalendar(id, data) {
    return axios.patch(`${this.url}/calendars/${id}`, { calendar: data });
  }

  deleteCalendar(id) {
    return axios.delete(`${this.url}/calendars/${id}`);
  }

  conversationSla(conversationId) {
    return axios.get(`${this.url}/conversations/${conversationId}/sla`);
  }
}

export default new SlaAPI();

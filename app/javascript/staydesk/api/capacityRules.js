/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

// /api/v1/accounts/:accountId/staydesk/capacity_rules
class CapacityRulesAPI extends ApiClient {
  constructor() {
    super('staydesk', { accountScoped: true });
  }

  list() {
    return axios.get(`${this.url}/capacity_rules`);
  }

  create(data) {
    return axios.post(`${this.url}/capacity_rules`, { capacity_rule: data });
  }

  update(id, data) {
    return axios.patch(`${this.url}/capacity_rules/${id}`, {
      capacity_rule: data,
    });
  }

  delete(id) {
    return axios.delete(`${this.url}/capacity_rules/${id}`);
  }
}

export default new CapacityRulesAPI();

/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

// /api/v1/accounts/:accountId/staydesk/agent_statuses e agent_status_periods
class AgentStatusesAPI extends ApiClient {
  constructor() {
    super('staydesk', { accountScoped: true });
  }

  list() {
    return axios.get(`${this.url}/agent_statuses`);
  }

  create(data) {
    return axios.post(`${this.url}/agent_statuses`, { agent_status: data });
  }

  update(id, data) {
    return axios.patch(`${this.url}/agent_statuses/${id}`, {
      agent_status: data,
    });
  }

  delete(id) {
    return axios.delete(`${this.url}/agent_statuses/${id}`);
  }

  loads() {
    return axios.get(`${this.url}/agent_loads`);
  }

  // As filas de carga configuradas na conta (chat, ticket, o que a operação definir)
  loadQueues() {
    return axios.get(`${this.url}/load_queues`);
  }

  offerStats() {
    return axios.get(`${this.url}/offer_stats`);
  }

  changeMine(agentStatusId) {
    return axios.post(`${this.url}/agent_status_periods`, {
      agent_status_id: agentStatusId,
    });
  }
}

export default new AgentStatusesAPI();

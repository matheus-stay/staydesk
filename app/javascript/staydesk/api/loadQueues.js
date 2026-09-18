/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

// /api/v1/accounts/:accountId/staydesk/load_queues
class LoadQueuesAPI extends ApiClient {
  constructor() {
    super('staydesk', { accountScoped: true });
  }

  list() {
    return axios.get(`${this.url}/load_queues`);
  }

  create(data) {
    return axios.post(`${this.url}/load_queues`, { load_queue: data });
  }

  update(id, data) {
    return axios.patch(`${this.url}/load_queues/${id}`, { load_queue: data });
  }

  delete(id) {
    return axios.delete(`${this.url}/load_queues/${id}`);
  }
}

export default new LoadQueuesAPI();

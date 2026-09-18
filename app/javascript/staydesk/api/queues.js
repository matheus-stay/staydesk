/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

// /api/v1/accounts/:accountId/staydesk/queues
class QueuesAPI extends ApiClient {
  constructor() {
    super('staydesk/queues', { accountScoped: true });
  }

  reorder(ids) {
    return axios.put(`${this.url}/reorder`, { ids });
  }
}

export default new QueuesAPI();

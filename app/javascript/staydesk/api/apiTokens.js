/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

// /api/v1/accounts/:accountId/staydesk/api_tokens
class ApiTokensAPI extends ApiClient {
  constructor() {
    super('staydesk', { accountScoped: true });
  }

  list() {
    return axios.get(`${this.url}/api_tokens`);
  }

  create(data) {
    return axios.post(`${this.url}/api_tokens`, { api_token: data });
  }

  update(id, data) {
    return axios.patch(`${this.url}/api_tokens/${id}`, { api_token: data });
  }

  delete(id) {
    return axios.delete(`${this.url}/api_tokens/${id}`);
  }
}

export default new ApiTokensAPI();

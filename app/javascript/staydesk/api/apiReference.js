/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

// /api/v1/accounts/:accountId/staydesk/api_reference
class ApiReferenceAPI extends ApiClient {
  constructor() {
    super('staydesk', { accountScoped: true });
  }

  show() {
    return axios.get(`${this.url}/api_reference`);
  }
}

export default new ApiReferenceAPI();

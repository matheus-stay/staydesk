/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

// /api/v1/accounts/:accountId/staydesk/offers
class OffersAPI extends ApiClient {
  constructor() {
    super('staydesk/offers', { accountScoped: true });
  }

  accept(id) {
    return axios.post(`${this.url}/${id}/accept`);
  }

  decline(id) {
    return axios.post(`${this.url}/${id}/decline`);
  }
}

export default new OffersAPI();

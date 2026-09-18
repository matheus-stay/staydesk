/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

// /api/v1/accounts/:accountId/staydesk/kpis — os números da operação, calculados
// no servidor para a Central, o dashboard e o MCP lerem a mesma conta.
class KpisAPI extends ApiClient {
  constructor() {
    super('staydesk', { accountScoped: true });
  }

  show({ since, until } = {}) {
    return axios.get(`${this.url}/kpis`, { params: { since, until } });
  }
}

export default new KpisAPI();

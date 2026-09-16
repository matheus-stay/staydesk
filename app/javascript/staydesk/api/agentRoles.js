/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

// /api/v1/accounts/:accountId/staydesk/agent_roles
class AgentRolesAPI extends ApiClient {
  constructor() {
    super('staydesk/agent_roles', { accountScoped: true });
  }

  setKind(userId, kind) {
    return axios.put(`${this.url}/${userId}`, { kind });
  }
}

export default new AgentRolesAPI();

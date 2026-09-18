/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

// /api/v1/accounts/:accountId/staydesk/agent_roles, roles e impersonations
class AgentRolesAPI extends ApiClient {
  constructor() {
    super('staydesk', { accountScoped: true });
  }

  listAgents() {
    return axios.get(`${this.url}/agent_roles`);
  }

  setKind(userId, kind) {
    return axios.put(`${this.url}/agent_roles/${userId}`, { kind });
  }

  setRole(userId, staydeskRoleId) {
    return axios.put(`${this.url}/agent_roles/${userId}`, {
      staydesk_role_id: staydeskRoleId,
    });
  }

  listRoles() {
    return axios.get(`${this.url}/roles`);
  }

  createRole(data) {
    return axios.post(`${this.url}/roles`, { role: data });
  }

  updateRole(id, data) {
    return axios.patch(`${this.url}/roles/${id}`, { role: data });
  }

  deleteRole(id) {
    return axios.delete(`${this.url}/roles/${id}`);
  }

  impersonate(userId) {
    return axios.post(`${this.url}/impersonations`, { user_id: userId });
  }

  listImpersonations() {
    return axios.get(`${this.url}/impersonations`);
  }
}

export default new AgentRolesAPI();

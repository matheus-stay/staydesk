/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

// /api/v1/accounts/:accountId/staydesk/workspace (resolvido para quem chama)
// /api/v1/accounts/:accountId/staydesk/team_workspaces (administração por time)
class WorkspaceAPI extends ApiClient {
  constructor() {
    super('staydesk', { accountScoped: true });
  }

  resolved() {
    return axios.get(`${this.url}/workspace`);
  }

  teamWorkspaces() {
    return axios.get(`${this.url}/team_workspaces`);
  }

  teamWorkspace(teamId) {
    return axios.get(`${this.url}/team_workspaces/${teamId}`);
  }

  updateTeamWorkspace(teamId, config) {
    return axios.put(`${this.url}/team_workspaces/${teamId}`, { config });
  }

  schema() {
    return axios.get(`${this.url}/team_workspaces/schema`);
  }
}

export default new WorkspaceAPI();

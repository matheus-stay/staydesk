/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

// /api/v1/accounts/:accountId/staydesk/team_views
class TeamViewsAPI extends ApiClient {
  constructor() {
    super('staydesk/team_views', { accountScoped: true });
  }

  counts() {
    return axios.get(`${this.url}/counts`);
  }

  conversations(id, { page = 1 } = {}) {
    return axios.get(`${this.url}/${id}/conversations`, { params: { page } });
  }

  create(data) {
    return axios.post(this.url, { team_view: data });
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}`, { team_view: data });
  }
}

export default new TeamViewsAPI();

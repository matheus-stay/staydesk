/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

// /api/v1/accounts/:accountId/staydesk/ticket_statuses e conversations/:id/ticket_status
class TicketStatusesAPI extends ApiClient {
  constructor() {
    super('staydesk', { accountScoped: true });
  }

  list() {
    return axios.get(`${this.url}/ticket_statuses`);
  }

  create(data) {
    return axios.post(`${this.url}/ticket_statuses`, { ticket_status: data });
  }

  update(id, data) {
    return axios.patch(`${this.url}/ticket_statuses/${id}`, {
      ticket_status: data,
    });
  }

  delete(id) {
    return axios.delete(`${this.url}/ticket_statuses/${id}`);
  }

  reorder(ids) {
    return axios.put(`${this.url}/ticket_statuses/reorder`, { ids });
  }

  apply(conversationId, ticketStatusId, snoozedUntil = null) {
    return axios.post(
      `${this.url}/conversations/${conversationId}/ticket_status`,
      { ticket_status_id: ticketStatusId, snoozed_until: snoozedUntil }
    );
  }
}

export default new TicketStatusesAPI();

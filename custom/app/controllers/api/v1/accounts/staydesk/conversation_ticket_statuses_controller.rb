# O agente aplica um status personalizado a uma conversa (pelo display_id).
class Api::V1::Accounts::Staydesk::ConversationTicketStatusesController < Api::V1::Accounts::Staydesk::BaseController
  before_action { authorize(Staydesk::TicketStatus, :apply?) }

  def create
    conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
    authorize conversation, :show?
    ticket_status = Staydesk::TicketStatus.active.where(account: Current.account).find(params.require(:ticket_status_id))
    snoozed_until = params[:snoozed_until].present? ? Time.zone.parse(params[:snoozed_until]) : nil
    @conversation = Staydesk::TicketStatusService.new(conversation).apply(ticket_status, snoozed_until: snoozed_until)
  end
end

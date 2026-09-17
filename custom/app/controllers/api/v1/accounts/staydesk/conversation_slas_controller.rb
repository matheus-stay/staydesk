# O SLA aplicado a uma conversa, pelo display_id, para o painel do agente.
class Api::V1::Accounts::Staydesk::ConversationSlasController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::AppliedSla) }

  def show
    conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
    @applied_sla = Staydesk::AppliedSla.includes(:sla_policy).find_by(conversation: conversation)
    head :no_content if @applied_sla.nil?
  end
end

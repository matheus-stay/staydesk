# POST: o agente troca o próprio status. GET: o dashboard lê os períodos (administrador).
class Api::V1::Accounts::Staydesk::AgentStatusPeriodsController < Api::V1::Accounts::Staydesk::BaseController
  MAX_LIMIT = 500

  before_action { check_authorization(Staydesk::AgentStatusPeriod) }

  def index
    scope = Staydesk::AgentStatusPeriod.where(account: Current.account).includes(:agent_status, :account_user)
    scope = scope.joins(:account_user).where(account_users: { user_id: params[:user_id] }) if params[:user_id].present?
    scope = scope.where(started_at: DateTime.parse(params[:since])..) if params[:since].present?
    scope = scope.where(started_at: ..DateTime.parse(params[:until])) if params[:until].present?
    scope = scope.where('staydesk_agent_status_periods.id > ?', params[:after_id]) if params[:after_id].present?
    @periods = scope.order(:id).limit([params.fetch(:limit, MAX_LIMIT).to_i, MAX_LIMIT].min)
  end

  def create
    agent_status = Staydesk::AgentStatus.active.where(account: Current.account).find(params.require(:agent_status_id))
    @current_status = Staydesk::AgentStatusService.new(Current.account_user).change_to(agent_status)
    render 'api/v1/accounts/staydesk/agent_statuses/current'
  end
end

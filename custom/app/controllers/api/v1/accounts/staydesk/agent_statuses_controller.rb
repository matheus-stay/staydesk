class Api::V1::Accounts::Staydesk::AgentStatusesController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::AgentStatus) }
  before_action :fetch_status, only: [:update, :destroy]

  def index
    @agent_statuses = scope.ordered
    @current_status = Staydesk::AgentStatusService.new(Current.account_user).current
  end

  def create
    @agent_status = Staydesk::AgentStatus.create!(permitted_payload.merge(account: Current.account, position: scope.count))
  end

  def update
    @agent_status.update!(permitted_payload)
  end

  def destroy
    @agent_status.destroy!
    head :no_content
  end

  private

  def scope
    Staydesk::AgentStatus.where(account: Current.account)
  end

  def fetch_status
    @agent_status = scope.find(params[:id])
  end

  def permitted_payload
    params.require(:agent_status).permit(
      :name, :color, :availability, :position,
      :offline_after_seconds, :offline_to_status_id, :counts_as_online, :active,
      inbox_ids: [], work_channels: []
    )
  end
end

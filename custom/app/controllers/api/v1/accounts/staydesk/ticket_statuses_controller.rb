class Api::V1::Accounts::Staydesk::TicketStatusesController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::TicketStatus) }
  before_action :fetch_status, only: [:update, :destroy]

  def index
    @ticket_statuses = scope.ordered
  end

  def create
    @ticket_status = Staydesk::TicketStatus.create!(permitted_payload.merge(account: Current.account, position: scope.count))
  end

  def update
    @ticket_status.update!(permitted_payload)
  end

  def destroy
    @ticket_status.destroy!
    head :no_content
  end

  def reorder
    ids = params.require(:ids).map(&:to_i)
    scope.where(id: ids).find_each { |status| status.update!(position: ids.index(status.id)) }
    @ticket_statuses = scope.ordered
    render :index
  end

  private

  def scope
    Staydesk::TicketStatus.where(account: Current.account)
  end

  def fetch_status
    @ticket_status = scope.find(params[:id])
  end

  def permitted_payload
    params.require(:ticket_status).permit(:name, :description, :color, :base_status, :default_for_base, :active, :position)
  end
end

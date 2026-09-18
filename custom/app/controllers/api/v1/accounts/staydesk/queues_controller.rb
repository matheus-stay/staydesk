# Filas de encaminhamento da conta (SPEC-15).
class Api::V1::Accounts::Staydesk::QueuesController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::Queue) }
  before_action :fetch_queue, only: [:update, :destroy]

  def index
    @queues = scope.ordered.includes(:team)
  end

  def create
    @queue = Staydesk::Queue.create!(permitted_payload.merge(account: Current.account, position: scope.count))
  end

  def update
    @queue.update!(permitted_payload)
  end

  def destroy
    @queue.destroy!
    head :no_content
  end

  def reorder
    ids = params.require(:ids).map(&:to_i)
    scope.where(id: ids).find_each { |fila| fila.update!(position: ids.index(fila.id)) }
    @queues = scope.ordered.includes(:team)
    render :index
  end

  private

  def scope
    Staydesk::Queue.where(account: Current.account)
  end

  def fetch_queue
    @queue = scope.find(params[:id])
  end

  def permitted_payload
    params.require(:queue).permit(
      :name, :description, :team_id, :fallback_mode,
      :priority_mode, :fallback_after_minutes, :accept_required, :accept_timeout_seconds,
      :position, :active, conditions: [{}], fallback_team_ids: [], channel_types: [], inbox_ids: []
    )
  end
end

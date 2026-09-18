class Api::V1::Accounts::Staydesk::LoadQueuesController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::LoadQueue) }
  before_action :fetch_queue, only: [:update, :destroy]

  def index
    @load_queues = Staydesk::LoadQueue.resolved(Current.account)
  end

  def create
    @load_queue = Staydesk::LoadQueue.create!(permitted_payload.merge(account: Current.account, position: scope.count))
  end

  def update
    @load_queue.update!(permitted_payload)
  end

  def destroy
    @load_queue.destroy!
    head :no_content
  end

  private

  def scope
    Staydesk::LoadQueue.where(account: Current.account)
  end

  def fetch_queue
    @load_queue = scope.find(params[:id])
  end

  def permitted_payload
    params.require(:load_queue).permit(:key, :name, :catch_all, :position, channel_types: [], inbox_ids: [])
  end
end

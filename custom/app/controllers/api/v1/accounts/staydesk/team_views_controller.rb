class Api::V1::Accounts::Staydesk::TeamViewsController < Api::V1::Accounts::Staydesk::BaseController
  COUNTS_TTL = 30.seconds

  before_action { check_authorization(Staydesk::TeamView) }
  before_action :fetch_team_view, only: [:show, :update, :destroy, :conversations]

  def index
    @team_views = visible_team_views
  end

  def show; end

  def create
    @team_view = Staydesk::TeamView.create!(permitted_payload.merge(account: Current.account, created_by: Current.user))
  end

  def update
    @team_view.update!(permitted_payload)
  end

  def destroy
    @team_view.destroy!
    head :no_content
  end

  def conversations
    result = filter_service(@team_view, page: params[:page]).perform
    @conversations = result[:conversations]
    @conversations_count = result[:count]
    render 'api/v1/accounts/conversations/filter'
  rescue CustomExceptions::CustomFilter::InvalidAttribute,
         CustomExceptions::CustomFilter::InvalidOperator,
         CustomExceptions::CustomFilter::InvalidQueryOperator,
         CustomExceptions::CustomFilter::InvalidValue => e
    render_could_not_create_error(e.message)
  end

  def counts
    views = visible_team_views.to_a
    @counts = Rails.cache.fetch(counts_cache_key(views), expires_in: COUNTS_TTL) do
      views.to_h { |view| [view.id, filter_service(view).perform[:count][:all_count]] }
    end
  end

  private

  def visible_team_views
    scope = Staydesk::TeamView.where(account: Current.account).ordered
    Current.account_user.administrator? ? scope : scope.visible_to(Current.user, Current.account)
  end

  def fetch_team_view
    @team_view = visible_team_views.find(params[:id])
  end

  def filter_service(view, page: nil)
    filter_params = ActionController::Parameters.new(
      payload: view.payload(Current.user), page: page, sort_by: view.sort_by
    ).permit!
    ::Conversations::FilterService.new(filter_params, Current.user, Current.account)
  end

  def counts_cache_key(views)
    "staydesk/team_views/counts/#{Current.account.id}/#{Current.user.id}/#{views.map(&:id).join('-')}"
  end

  def permitted_payload
    params.require(:team_view).permit(
      :name, :description, :color, :icon, :sort_by, :position,
      columns: [], team_ids: [], query: {}
    )
  end
end

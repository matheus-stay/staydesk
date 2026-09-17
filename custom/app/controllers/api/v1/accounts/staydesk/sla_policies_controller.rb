class Api::V1::Accounts::Staydesk::SlaPoliciesController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::SlaPolicy) }
  before_action :fetch_policy, only: [:show, :update, :destroy]

  def index
    @sla_policies = scope.ordered
  end

  def show; end

  def create
    @sla_policy = Staydesk::SlaPolicy.create!(permitted_payload.merge(account: Current.account, position: scope.count))
  end

  def update
    @sla_policy.update!(permitted_payload)
  end

  def destroy
    @sla_policy.destroy!
    head :no_content
  end

  # PUT reorder { ids: [...] }: a ordem é a prioridade de escolha da política.
  def reorder
    ids = params.require(:ids).map(&:to_i)
    scope.where(id: ids).find_each { |policy| policy.update!(position: ids.index(policy.id)) }
    @sla_policies = scope.ordered
    render :index
  end

  private

  def scope
    Staydesk::SlaPolicy.where(account: Current.account)
  end

  def fetch_policy
    @sla_policy = scope.find(params[:id])
  end

  def permitted_payload
    params.require(:sla_policy).permit(
      :name, :description, :active, :calendar_id, :warning_ratio,
      pause_statuses: [], conditions: [:attribute_key, :filter_operator, :query_operator, :custom_attribute_type, { values: [] }],
      targets: {}
    ).tap do |payload|
      payload[:calendar_id] = Staydesk::Calendar.where(account: Current.account).find(payload[:calendar_id]).id if payload[:calendar_id].present?
    end
  end
end

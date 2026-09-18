# Regras de capacidade da conta: quantas conversas de cada canal de trabalho o
# agente aguenta ao mesmo tempo, como no Zendesk.
class Api::V1::Accounts::Staydesk::CapacityRulesController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::CapacityRule) }
  before_action :fetch_rule, only: [:update, :destroy]

  def index
    @capacity_rules = scope.ordered
  end

  def create
    @capacity_rule = Staydesk::CapacityRule.create!(permitted_payload.merge(account: Current.account, position: scope.count))
  end

  def update
    @capacity_rule.update!(permitted_payload)
  end

  def destroy
    @capacity_rule.destroy!
    head :no_content
  end

  private

  def scope
    Staydesk::CapacityRule.where(account: Current.account)
  end

  def fetch_rule
    @capacity_rule = scope.find(params[:id])
  end

  def permitted_payload
    params.require(:capacity_rule).permit(:name, :description, :is_default, :position, :missed_offers_limit,
                                          :missed_offers_to_status_id, limits: {}, user_ids: [])
  end
end

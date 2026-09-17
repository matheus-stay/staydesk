# Varredura dos SLAs aplicados para o dashboard: por janela de atualização, status e cursor.
class Api::V1::Accounts::Staydesk::AppliedSlasController < Api::V1::Accounts::Staydesk::BaseController
  MAX_LIMIT = 500

  before_action { check_authorization(Staydesk::AppliedSla) }

  def index
    scope = Staydesk::AppliedSla.where(account: Current.account).includes(:sla_policy, :conversation)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(updated_at: DateTime.parse(params[:since])..) if params[:since].present?
    scope = scope.where(updated_at: ..DateTime.parse(params[:until])) if params[:until].present?
    scope = scope.where('id > ?', params[:after_id]) if params[:after_id].present?
    @applied_slas = scope.order(:id).limit([params.fetch(:limit, MAX_LIMIT).to_i, MAX_LIMIT].min)
  end
end

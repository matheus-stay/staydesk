# Papel StayDesk (full ou light) por agente da conta, chaveado pelo id do usuário.
class Api::V1::Accounts::Staydesk::AgentRolesController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::AccountUserRole) }

  def index
    @account_users = Current.account.account_users.includes(:user, :staydesk_role).order(:id)
  end

  def update
    account_user = Current.account.account_users.find_by!(user_id: params[:user_id])
    role = Staydesk::AccountUserRole.find_or_initialize_by(account_user: account_user)
    role.update!(kind: params.require(:kind))
    @account_users = [account_user.reload]
    render :index
  end
end

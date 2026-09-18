# Papel StayDesk por agente da conta, chaveado pelo id do usuário: o tipo
# (full ou light) e o papel com permissões granulares, concedido ou revogado a
# qualquer momento (SPEC-05 e SPEC-12).
class Api::V1::Accounts::Staydesk::AgentRolesController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::AccountUserRole) }

  def index
    @account_users = Current.account.account_users.includes(:user, :staydesk_role).order(:id)
  end

  def update
    account_user = Current.account.account_users.find_by!(user_id: params[:user_id])
    vinculo = Staydesk::AccountUserRole.find_or_initialize_by(account_user: account_user)
    vinculo.kind = params[:kind] if params.key?(:kind)
    vinculo.staydesk_role_id = papel_pedido if params.key?(:staydesk_role_id)
    vinculo.save!
    @account_users = [account_user.reload]
    render :index
  end

  private

  # `null` revoga o papel; qualquer id precisa ser um papel desta conta.
  def papel_pedido
    id = params[:staydesk_role_id]
    return nil if id.blank?

    Staydesk::Role.where(account: Current.account).find(id).id
  end
end

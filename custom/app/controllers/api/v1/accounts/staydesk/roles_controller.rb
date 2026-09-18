# Papéis com permissões granulares da conta (SPEC-12).
class Api::V1::Accounts::Staydesk::RolesController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::Role) }
  before_action :fetch_role, only: [:update, :destroy]

  def index
    @roles = scope.ordered
    @permissions = Staydesk::Role.permissions
  end

  def create
    @role = Staydesk::Role.create!(permitted_payload.merge(account: Current.account, position: scope.count))
  end

  def update
    @role.update!(permitted_payload)
  end

  def destroy
    @role.destroy!
    head :no_content
  end

  private

  def scope
    Staydesk::Role.where(account: Current.account)
  end

  def fetch_role
    @role = scope.find(params[:id])
  end

  def permitted_payload
    params.require(:role).permit(:name, :description, :position, permissions: [])
  end
end

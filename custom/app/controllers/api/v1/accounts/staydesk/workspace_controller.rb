# A área de trabalho já resolvida para quem chama (qualquer papel).
class Api::V1::Accounts::Staydesk::WorkspaceController < Api::V1::Accounts::Staydesk::BaseController
  def show
    render json: Staydesk::WorkspaceResolver.new(user: Current.user, account: Current.account).resolve
  end
end

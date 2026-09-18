# Tokens de API com escopo próprio. O valor só volta na criação; depois, nem o
# dono lê de novo, só revoga e cria outro.
class Api::V1::Accounts::Staydesk::ApiTokensController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::ApiToken) }
  before_action :fetch_token, only: [:update, :destroy]

  def index
    @api_tokens = escopo.ordered
    @scopes = Staydesk::ApiScope.todos
  end

  def create
    @api_token = Staydesk::ApiToken.gerar!(
      permitted_payload.merge(account: Current.account, user: usuario_do_token)
    )
  end

  def update
    @api_token.update!(permitted_payload.except(:user_id))
  end

  def destroy
    @api_token.destroy!
    head :no_content
  end

  private

  def escopo
    Staydesk::ApiToken.where(account: Current.account)
  end

  def fetch_token
    @api_token = escopo.find(params[:id])
  end

  # Sem usuário informado, o token age por quem o criou.
  def usuario_do_token
    informado = params[:api_token][:user_id]
    return Current.user if informado.blank?

    Current.account.users.find(informado)
  end

  def permitted_payload
    params.require(:api_token).permit(:name, :description, :expires_at, :active, :user_id, scopes: [])
  end
end

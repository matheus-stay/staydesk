# Entrar como o agente (SPEC-13): devolve um link de sessão do próprio Chatwoot,
# válido por cinco minutos, e guarda a trilha de quem entrou como quem.
class Api::V1::Accounts::Staydesk::ImpersonationsController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::Impersonation) }

  def index
    @impersonations = Staydesk::Impersonation.where(account: Current.account).recent.includes(:actor, :target).limit(30)
  end

  def create
    alvo = Current.account.users.find(params.require(:user_id))
    return render json: { error: 'Não é possível entrar como um super administrador' }, status: :forbidden if alvo.is_a?(SuperAdmin)

    @impersonation = Staydesk::Impersonation.create!(
      account: Current.account, actor: current_user, target: alvo, expires_at: 5.minutes.from_now
    )
    @url = alvo.generate_sso_link_with_impersonation
  end
end

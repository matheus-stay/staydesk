# Entra em AccessTokenAuthHelper pelo gancho prepend_mod_with.
#
# O Chatwoot só conhece o token pessoal, que carrega tudo que a pessoa pode. Aqui
# entra o token de API do StayDesk: ele age em nome de um usuário da conta, mas
# só alcança o que o escopo dele permite (Staydesk::ApiScope).
module Custom::AccessTokenAuthHelper
  def ensure_access_token
    super
    return if @access_token.present?

    Current.staydesk_api_token = Staydesk::ApiToken.autenticar(staydesk_token_do_cabecalho)
  end

  def authenticate_access_token!
    ensure_access_token
    return super if Current.staydesk_api_token.blank?

    @resource = Current.staydesk_api_token.user
    Current.user = @resource
    Current.staydesk_api_token.registrar_uso!
    staydesk_guard_api_scopes
  end

  private

  # O escopo é checado aqui, e não numa guarda geral, porque só depois de
  # autenticar se sabe qual token entrou. Endpoint que nenhum grupo de escopo
  # cobre não passa: é permissão explícita, não lista de bloqueio.
  def staydesk_guard_api_scopes
    token = Current.staydesk_api_token
    return if token.autoriza?(controller_path, request.request_method)

    render json: { error: staydesk_erro_de_escopo }, status: :forbidden
  end

  def staydesk_erro_de_escopo
    exigido = Staydesk::ApiScope.exigido(controller_path, request.request_method)
    return 'This token has no scope for this endpoint' if exigido.blank?

    "This token is missing the scope #{exigido}"
  end

  def staydesk_token_do_cabecalho
    request.headers[:api_access_token] || request.headers[:HTTP_API_ACCESS_TOKEN]
  end
end

# Fachada Zendesk (SPEC-17): o dashboard da casa consome a API do Zendesk para
# popular o banco dele; aqui os mesmos caminhos e formatos saem das conversas
# do StayDesk. Autentica como o Zendesk (Basic `email/token:TOKEN`) ou pelo
# cabeçalho `api_access_token`; o TOKEN é um token de API do StayDesk (com os
# escopos dele) ou o token de acesso de um usuário.
class Staydesk::Zendesk::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  before_action :autenticar!

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: 'RecordNotFound', description: 'Not found' }, status: :not_found
  end
  rescue_from ActiveRecord::RecordInvalid do |erro|
    render json: { error: 'RecordInvalid', description: erro.message }, status: :unprocessable_entity
  end

  private

  attr_reader :conta

  def autenticar!
    valor = token_do_pedido
    if (token = Staydesk::ApiToken.autenticar(valor))
      @conta = token.account
      Current.user = token.user
      Current.staydesk_api_token = token
      token.registrar_uso!
    elsif (acesso = AccessToken.find_by(token: valor.presence))&.owner.is_a?(User)
      Current.user = acesso.owner
      @conta = conta_do_usuario(acesso.owner)
    end
    return if @conta.present? && escopo_ok?

    render json: { error: 'Couldn\'t authenticate you' }, status: :unauthorized
  end

  # Basic `email/token:TOKEN` (como o Zendesk) ou o cabeçalho do produto.
  def token_do_pedido
    cabecalho = request.headers[:api_access_token] || request.headers[:HTTP_API_ACCESS_TOKEN]
    return cabecalho if cabecalho.present?

    credenciais = authenticate_with_http_basic { |_usuario, senha| senha }
    credenciais.presence || params[:api_token]
  end

  # Token de usuário serve várias contas: `account_id` no cabeçalho ou na query,
  # senão a primeira conta dele.
  def conta_do_usuario(usuario)
    pedida = request.headers['X-Account-Id'].presence || params[:account_id].presence
    pedida ? usuario.accounts.find_by(id: pedida) : usuario.accounts.first
  end

  # Token do StayDesk respeita o escopo: leitura pede leitura, escrita pede escrita.
  def escopo_ok?
    token = Current.staydesk_api_token
    return true if token.blank?

    token.scopes.include?(escopo_exigido)
  end

  def escopo_exigido
    "#{self.class::ESCOPO}:#{request.get? || request.head? ? 'leitura' : 'escrita'}"
  end

  def serializador
    @serializador ||= Staydesk::Zendesk::Serializer.new(conta)
  end

  def unix(valor, padrao)
    valor.present? ? Time.zone.at(valor.to_i) : padrao
  end
end

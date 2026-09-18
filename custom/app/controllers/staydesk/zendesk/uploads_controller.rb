# Upload de anexo: o Zendesk devolve um token para anexar num comentário. Aqui
# ainda não há esse fluxo; o dashboard trata o 501 como "sem anexo".
class Staydesk::Zendesk::UploadsController < Staydesk::Zendesk::BaseController
  ESCOPO = 'conversas'.freeze

  def create
    render json: { error: 'NotImplemented', description: 'Anexos por upload ainda não são suportados nesta fachada.' }, status: :not_implemented
  end
end

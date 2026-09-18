# A referência da API, servida para a Central desenhar a página de documentação.
# É o mesmo arquivo que o teste confere contra as rotas, então o que está aqui
# existe de verdade.
class Api::V1::Accounts::Staydesk::ApiReferenceController < Api::V1::Accounts::Staydesk::BaseController
  def show
    render json: Staydesk::ApiReference.conteudo
  end
end

# Campos do ticket: o catálogo da conta e, quando pedido para uma conversa, o
# valor de cada campo nela e o que falta para poder resolver. Preencher também
# passa por aqui, então quem integra não precisa montar o JSON de atributos na mão.
class Api::V1::Accounts::Staydesk::TicketFieldsController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::TicketField) }
  before_action :fetch_conversation, only: [:show, :update]

  def index
    @ticket_fields = servico.definicoes
  end

  def show
    @campos = servico.para_conversa(@conversation)
    @faltando = servico.faltando(@conversation).map(&:attribute_key)
  end

  # Preenche os campos informados, deixando os demais como estão.
  def update
    valores = params.require(:custom_attributes).permit!.to_h
    @conversation.update!(custom_attributes: (@conversation.custom_attributes || {}).merge(valores))
    @campos = servico.para_conversa(@conversation.reload)
    @faltando = servico.faltando(@conversation).map(&:attribute_key)
    render :show
  end

  private

  def servico
    @servico ||= Staydesk::TicketFieldService.new(Current.account)
  end

  def fetch_conversation
    @conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
    authorize(@conversation, :show?)
  end
end

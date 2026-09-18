# Campos do ticket no formato do Zendesk: os atributos personalizados de conversa.
class Staydesk::Zendesk::TicketFieldsController < Staydesk::Zendesk::BaseController
  ESCOPO = 'relatorios'.freeze

  def index
    campos = definicoes.order(:id).map { |definicao| serializador.campo_do_ticket(definicao) }
    render json: { ticket_fields: campos, next_page: nil, count: campos.size }
  end

  def show
    render json: { ticket_field: serializador.campo_do_ticket(definicoes.find(params[:id])) }
  end

  private

  def definicoes
    conta.custom_attribute_definitions.where(attribute_model: 'conversation_attribute')
  end
end

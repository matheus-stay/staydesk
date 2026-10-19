# "Enviar como <status>" numa chamada só: preenche campos do ticket, manda a
# resposta (ou nota) e aplica o status, tudo ou nada. Faltando campo obrigatório
# para resolver, nada é gravado e a resposta diz quais faltam. Sem `content`, só
# grava os campos e o status (resolver sem escrever, como no Zendesk).
class Api::V1::Accounts::Staydesk::ConversationRepliesController < Api::V1::Accounts::Staydesk::BaseController
  def create
    @conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
    authorize @conversation, :show?
    ActiveRecord::Base.transaction do
      gravar_campos
      responder if params[:content].present?
      aplicar_status
    end
    render 'api/v1/accounts/staydesk/conversation_ticket_statuses/create'
  rescue ActiveRecord::RecordInvalid => e
    render json: { message: e.record.errors.full_messages.to_sentence, missing_to_resolve: faltando }, status: :unprocessable_entity
  end

  private

  def gravar_campos
    novos = params[:custom_attributes]&.to_unsafe_h
    return if novos.blank?

    @conversation.update!(custom_attributes: (@conversation.custom_attributes || {}).merge(novos))
  end

  def responder
    Messages::MessageBuilder.new(Current.user, @conversation, params.permit(:content, :private, :content_type)).perform
  end

  def aplicar_status
    return if params[:ticket_status_id].blank?

    authorize Staydesk::TicketStatus, :apply?
    status = Staydesk::TicketStatus.active.where(account: Current.account).find(params[:ticket_status_id])
    Staydesk::TicketStatusService.new(@conversation.reload).apply(status)
  end

  def faltando
    Staydesk::TicketFieldService.new(Current.account).faltando(@conversation).map(&:attribute_key)
  end
end

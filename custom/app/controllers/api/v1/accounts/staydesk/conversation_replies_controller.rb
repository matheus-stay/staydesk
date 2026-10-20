# "Enviar como <status>" numa chamada só: preenche campos do ticket, manda a
# resposta (ou nota) e aplica o status. Faltando campo obrigatório para resolver,
# nada é gravado e a resposta diz quais faltam: isso é conferido antes de gravar.
# Sem `content`, só grava os campos e o status (resolver sem escrever, como no
# Zendesk).
#
# O status vai num save próprio, depois do commit de campos e resposta. No mesmo
# commit, a primeira resposta grava a conversa de novo (first_reply_created_at) e
# apaga a mudança de status antes de o produto avisar: SLA, gatilhos e pesquisa
# de satisfação não ficavam sabendo que o ticket foi para espera ou resolvido.
class Api::V1::Accounts::Staydesk::ConversationRepliesController < Api::V1::Accounts::Staydesk::BaseController
  def create
    @conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
    authorize @conversation, :show?
    status = status_pedido
    return recusar_por_campos if status&.base_status == 'resolved' && faltando_com_campos_novos.any?

    gravar_e_responder
    Staydesk::TicketStatusService.new(@conversation.reload).apply(status) if status
    render 'api/v1/accounts/staydesk/conversation_ticket_statuses/create'
  rescue ActiveRecord::RecordInvalid => e
    render json: { message: e.record.errors.full_messages.to_sentence, missing_to_resolve: faltando }, status: :unprocessable_entity
  end

  private

  def gravar_e_responder
    ActiveRecord::Base.transaction do
      gravar_campos
      responder if params[:content].present?
    end
  end

  def status_pedido
    return if params[:ticket_status_id].blank?

    authorize Staydesk::TicketStatus, :apply?
    Staydesk::TicketStatus.active.where(account: Current.account).find(params[:ticket_status_id])
  end

  # Os campos obrigatórios como ficariam depois de gravar os que vieram no pedido.
  def faltando_com_campos_novos
    novos = params[:custom_attributes]&.to_unsafe_h || {}
    @conversation.custom_attributes = (@conversation.custom_attributes || {}).merge(novos)
    Staydesk::TicketFieldService.new(Current.account).faltando(@conversation)
  ensure
    @conversation.restore_attributes([:custom_attributes])
  end

  def recusar_por_campos
    faltando_agora = faltando_com_campos_novos
    render json: { message: I18n.t('staydesk.ticket_fields.required_to_resolve', fields: faltando_agora.map(&:attribute_display_name).join(', ')),
                   missing_to_resolve: faltando_agora.map(&:attribute_key) }, status: :unprocessable_entity
  end

  def gravar_campos
    novos = params[:custom_attributes]&.to_unsafe_h
    return if novos.blank?

    @conversation.update!(custom_attributes: (@conversation.custom_attributes || {}).merge(novos))
  end

  def responder
    Messages::MessageBuilder.new(Current.user, @conversation, params.permit(:content, :private, :content_type)).perform
  end

  def faltando
    Staydesk::TicketFieldService.new(Current.account).faltando(@conversation).map(&:attribute_key)
  end
end

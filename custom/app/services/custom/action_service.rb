# Entra em ActionService pelo gancho include_mod_with('ActionService'), então vale
# para automações e para macros ao mesmo tempo. São as ações que o Zendesk tem e o
# Chatwoot community não: escrever num campo da conversa e aplicar status do ticket.
module Custom::ActionService
  # ['chave_do_atributo', 'valor'] — valor vazio limpa o campo.
  def staydesk_set_attribute(params)
    chave, valor = Array(params).flatten
    return if chave.blank?

    atributos = (@conversation.custom_attributes || {}).dup
    valor.presence ? atributos[chave.to_s] = valor : atributos.delete(chave.to_s)
    @conversation.update!(custom_attributes: atributos)
  end

  # [id_do_status] do catálogo da SPEC-10: grava o atributo e alinha o status base.
  def staydesk_set_ticket_status(params)
    id = Array(params).flatten.first
    status = Staydesk::TicketStatus.active.find_by(account_id: @conversation.account_id, id: id)
    return if status.blank?

    Staydesk::TicketStatusService.new(@conversation).apply(status)
  end
end

# O bloco `staydesk` que acompanha toda conversa na API e nos eventos em tempo
# real: o que um front precisa mostrar e não deve recalcular sozinho. Assunto,
# status do ticket já resolvido (com id) e os campos que faltam para resolver.
# Catálogos da conta ficam guardados por pedido, para a lista não fazer uma
# consulta por conversa.
class Staydesk::ConversationPayload
  def initialize(conversation)
    @conversa = conversation
  end

  def to_h
    { subject: Staydesk::ConversationSubject.new(@conversa).to_s, ticket_status: ticket_status,
      missing_to_resolve: faltando }
  end

  private

  def ticket_status
    nome = @conversa.custom_attributes.to_h[Staydesk::TicketStatus::ATTRIBUTE_KEY]
    status = (nome.present? && catalogo[nome]) || Staydesk::TicketStatus.default_for(@conversa.account, @conversa.status)
    return if status.blank?

    { id: status.id, name: status.name, color: status.color, base_status: status.base_status }
  end

  def faltando
    campos.faltando(@conversa).map(&:attribute_key)
  end

  def catalogo
    guardado(:ticket_statuses) { Staydesk::TicketStatus.where(account_id: @conversa.account_id).index_by(&:name) }
  end

  def campos
    guardado(:ticket_fields) { Staydesk::TicketFieldService.new(@conversa.account) }
  end

  def guardado(nome, &)
    Staydesk::Requisicao.guardar([nome, @conversa.account_id], &)
  end
end

# Aplica um status personalizado a uma conversa: grava o atributo e alinha o status
# base do Chatwoot (aberto, pendente, adiado, resolvido) na mesma operação.
class Staydesk::TicketStatusService
  ATTRIBUTE_KEY = Staydesk::TicketStatus::ATTRIBUTE_KEY

  def initialize(conversation)
    @conversation = conversation
  end

  def current
    name = @conversation.custom_attributes&.dig(ATTRIBUTE_KEY)
    return nil if name.blank?

    Staydesk::TicketStatus.find_by(account_id: @conversation.account_id, name: name)
  end

  def apply(ticket_status, snoozed_until: nil)
    attributes = (@conversation.custom_attributes || {}).merge(ATTRIBUTE_KEY => ticket_status.name)
    @conversation.custom_attributes = attributes
    @conversation.status = ticket_status.base_status
    @conversation.snoozed_until = ticket_status.base_status == 'snoozed' ? snoozed_until : nil
    @conversation.save!
    @conversation
  end

  # O caso ganhou responsável: entra no status de trabalho em curso. Voltou para a
  # fila sem ninguém: desfaz, para não ficar "em andamento" parado esperando dono.
  def follow_assignment!
    em_andamento = Staydesk::TicketStatus.on_assign(@conversation.account)
    return if em_andamento.blank?

    @conversation.assignee_id.present? ? assumir(em_andamento) : devolver(em_andamento)
  end

  # Chamado quando o status base mudou por outro caminho (botão do upstream, automação,
  # bot): mantém o atributo coerente com o status base novo.
  def align_with_base!
    ticket_status = current
    return if ticket_status&.base_status == @conversation.status

    default = Staydesk::TicketStatus.default_for(@conversation.account, @conversation.status)
    attributes = (@conversation.custom_attributes || {})
    new_attributes = default ? attributes.merge(ATTRIBUTE_KEY => default.name) : attributes.except(ATTRIBUTE_KEY)
    return if new_attributes == attributes

    @conversation.update!(custom_attributes: new_attributes)
  end

  private

  def assumir(em_andamento)
    return unless @conversation.status == 'open'
    return if current&.id == em_andamento.id

    apply(em_andamento)
  end

  def devolver(em_andamento)
    return unless current&.id == em_andamento.id

    inicial = Staydesk::TicketStatus.default_for(@conversation.account, 'open')
    apply(inicial) if inicial && inicial.id != em_andamento.id
  end
end

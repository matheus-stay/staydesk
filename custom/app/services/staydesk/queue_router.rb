# Passa a conversa pelas filas, na ordem, e entrega ao time da primeira que casar.
# Só age quando a conversa ainda não tem time: fila não briga com decisão humana.
class Staydesk::QueueRouter
  RuleShim = Struct.new(:id, :account, :account_id, :conditions, :event_name, keyword_init: true) do
    def authorization_error!; end
  end

  def initialize(conversation)
    @conversation = conversation
  end

  def perform
    return if @conversation.team_id.present?

    fila = match
    return if fila.blank?

    @conversation.update!(team: fila.team)
    fila
  end

  # A fila desta conversa quando ela ainda nem foi gravada, para o grupo já
  # nascer definido: a distribuição automática corre em paralelo e, se o grupo
  # chegar depois, ela atribui sem passar pelo aceite. Só decide quando a
  # resposta é inequívoca; fila que depende de condições precisa da conversa
  # gravada, então nesse caso a decisão fica para o roteamento pós-criação.
  def match_inline
    Staydesk::Queue.active.where(account_id: @conversation.account_id).ordered.each do |fila|
      next unless fila.atende_canal?(@conversation.inbox)
      return nil if fila.conditions.present?

      return fila
    end
    nil
  end

  def match
    Staydesk::Queue.active.where(account_id: @conversation.account_id).ordered.find { |fila| matches?(fila) }
  end

  private

  def matches?(fila)
    return false unless fila.atende_canal?(@conversation.inbox)
    return true if fila.conditions.blank?

    shim = RuleShim.new(id: fila.id, account: fila.account, account_id: fila.account_id,
                        conditions: fila.conditions, event_name: 'conversation_updated')
    ::AutomationRules::ConditionsFilterService.new(shim, @conversation, {}).perform.present?
  end
end

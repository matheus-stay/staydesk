# Os filtros dos indicadores, compartilhados por quem calcula: `user_id`
# (agente), `load_queue` (canal de trabalho, pela chave) e `team_id` (grupo).
# O de agente entra onde o agente aparece (avaliação, evento, convite); os
# outros dois recortam as conversas.
module Staydesk::Kpi::Recortes
  private

  def conversas_filtradas
    escopo = @account.conversations
    escopo = escopo.where(inbox_id: caixas_do_canal(@filtros[:load_queue])) if @filtros[:load_queue].present?
    escopo = escopo.where(team_id: @filtros[:team_id]) if @filtros[:team_id].present?
    escopo
  end

  def filtra_conversa?
    @filtros[:load_queue].present? || @filtros[:team_id].present?
  end

  def caixas_do_canal(chave)
    @account.inboxes.select { |caixa| Staydesk::LoadQueue.for_inbox(caixa)&.key == chave.to_s }.map(&:id)
  end

  def agente_filtrado
    @filtros[:user_id].presence&.to_i
  end

  # Aplica os recortes a um escopo que tem `conversation_id` e uma coluna de agente.
  def recortar(escopo, agente:)
    escopo = escopo.where(agente => agente_filtrado) if agente_filtrado
    escopo = escopo.where(conversation_id: conversas_filtradas.select(:id)) if filtra_conversa?
    escopo
  end
end

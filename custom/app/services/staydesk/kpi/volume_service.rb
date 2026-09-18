# Os números de volume e de prazo que a coordenação olha no dashboard: quantas
# entraram e quantas foram resolvidas no período, a fila real de agora (sem
# recorte de data), reaberturas, resolução no primeiro contato e o percentual
# dentro do SLA. Respeita os mesmos recortes do resto.
class Staydesk::Kpi::VolumeService
  include Staydesk::Kpi::Recortes

  def initialize(account:, since:, ate:, filtros: {})
    @account = account
    @since = since
    @ate = ate
    @filtros = filtros
  end

  def volumes
    {
      criadas: criadas.count, resolvidas: resolvidas.count,
      abertas_agora: abertas_agora.count, esperando_suporte: abertas_agora.where(status: 'open').count,
      vencidas_agora: vencidas_agora, reabertas: reabertas.count,
      fcr_percentual: fcr[:percentual], fcr_base: fcr[:base]
    }
  end

  # Percentual atendido dentro do prazo, entre as conversas que tiveram o prazo e foram atendidas.
  def sla
    aplicados = recortar_sla(Staydesk::AppliedSla.where(account_id: @account.id, created_at: periodo))
    {
      primeira_resposta: dentro_do_prazo(aplicados, :first_response),
      resolucao: dentro_do_prazo(aplicados, :resolution)
    }
  end

  private

  def periodo
    @since..@ate
  end

  def criadas
    base = conversas_filtradas.where(created_at: periodo)
    agente_filtrado ? base.where(assignee_id: agente_filtrado) : base
  end

  def resolvidas
    recortar(ReportingEvent.where(account_id: @account.id, name: 'conversation_resolved', created_at: periodo), agente: :user_id)
  end

  # A fila real: o que está aberto agora, sem olhar a data de criação.
  def abertas_agora
    base = conversas_filtradas.where(status: %w[open pending snoozed])
    agente_filtrado ? base.where(assignee_id: agente_filtrado) : base
  end

  def vencidas_agora
    Staydesk::AppliedSla.where(account_id: @account.id, conversation_id: abertas_agora.select(:id))
                        .where.not(breached_metrics: []).count
  end

  def reabertas
    escopo = Staydesk::ConversationEvent.where(account_id: @account.id, kind: 'status_changed', from_value: 'resolved',
                                               to_value: 'open', created_at: periodo)
    recortar(escopo, agente: :user_id)
  end

  # Resolvida com uma resposta só do agente e sem reabrir: resolveu de primeira.
  def fcr
    @fcr ||= calcular_fcr(resolvidas.pluck(:conversation_id).uniq)
  end

  def calcular_fcr(ids)
    return { percentual: nil, base: 0 } if ids.empty?

    respostas = Message.where(conversation_id: ids, message_type: :outgoing, private: false).group(:conversation_id).count
    reabertas_ids = Staydesk::ConversationEvent.where(conversation_id: ids, kind: 'status_changed', from_value: 'resolved', to_value: 'open')
                                               .distinct.pluck(:conversation_id)
    de_primeira = ids.count { |id| respostas.fetch(id, 0) <= 1 && reabertas_ids.exclude?(id) }
    { percentual: (de_primeira * 100.0 / ids.size).round(1), base: ids.size }
  end

  def recortar_sla(escopo)
    escopo = escopo.where(conversation_id: conversas_filtradas.select(:id)) if filtra_conversa?
    escopo = escopo.where(conversation_id: @account.conversations.where(assignee_id: agente_filtrado).select(:id)) if agente_filtrado
    escopo
  end

  def dentro_do_prazo(aplicados, metrica)
    com_prazo = aplicados.where.not("#{metrica}_due_at" => nil).where.not("#{metrica}_met_at" => nil)
    base = com_prazo.count
    return { percentual: nil, base: 0 } if base.zero?

    dentro = com_prazo.where("#{metrica}_met_at <= #{metrica}_due_at").count
    { percentual: (dentro * 100.0 / base).round(1), base: base }
  end
end

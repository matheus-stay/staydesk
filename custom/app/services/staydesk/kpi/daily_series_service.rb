# Conversas criadas, resolvidas e respostas de CSAT por dia, para a tendência
# dos indicadores. Respeita os mesmos recortes do resto.
class Staydesk::Kpi::DailySeriesService
  include Staydesk::Kpi::Recortes

  def initialize(account:, since:, ate:, filtros: {})
    @account = account
    @since = since
    @ate = ate
    @filtros = filtros
  end

  def perform
    criadas = por_dia(criadas_no_periodo)
    resolvidas = por_dia(recortar(eventos('conversation_resolved'), agente: :user_id))
    csat = por_dia(recortar(CsatSurveyResponse.where(account_id: @account.id, created_at: periodo), agente: :assigned_agent_id))
    (@since.to_date..@ate.to_date).map do |dia|
      { dia: dia.iso8601, criadas: criadas[dia] || 0, resolvidas: resolvidas[dia] || 0, csat_respostas: csat[dia] || 0 }
    end
  end

  private

  def periodo
    @since..@ate
  end

  def criadas_no_periodo
    base = conversas_filtradas.where(created_at: periodo)
    agente_filtrado ? base.where(assignee_id: agente_filtrado) : base
  end

  def eventos(nome)
    ReportingEvent.where(account_id: @account.id, name: nome, created_at: periodo)
  end

  def por_dia(escopo)
    escopo.group(Arel.sql('DATE(created_at)')).count
  end
end

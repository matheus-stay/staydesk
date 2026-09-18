# Eventos de métrica de ticket no formato do Zendesk, a partir do SLA aplicado
# em cada conversa: apply_sla, fulfill e breach, por métrica.
class Staydesk::Zendesk::MetricEventsController < Staydesk::Zendesk::BaseController
  ESCOPO = 'relatorios'.freeze
  METRICAS = { 'first_response' => ['reply_time', 1], 'next_response' => ['reply_time', 2], 'resolution' => ['resolution_time', 1] }.freeze

  def incremental
    desde = unix(params[:start_time], Time.zone.at(0))
    aplicados = Staydesk::AppliedSla.where(account_id: conta.id, updated_at: desde..)
                                    .includes(:conversation, :sla_policy).order(:updated_at).limit(1000)
    eventos = aplicados.flat_map { |aplicado| eventos_de(aplicado) }
    render json: { ticket_metric_events: eventos, end_of_stream: true,
                   end_time: (aplicados.last&.updated_at || Time.current).to_i, next_page: nil, count: eventos.size }
  end

  private

  def eventos_de(aplicado)
    ticket = aplicado.conversation&.display_id
    return [] if ticket.blank?

    METRICAS.flat_map do |chave, (metrica, instancia)|
      eventos_da_metrica(aplicado, chave, base: { ticket_id: ticket, metric: metrica, instance_id: instancia })
    end
  end

  # apply_sla quando o prazo nasce; fulfill se cumpriu no prazo; breach se passou.
  def eventos_da_metrica(aplicado, chave, base:)
    prazo = aplicado.public_send("#{chave}_due_at")
    return [] if prazo.blank?

    cumprido = aplicado.public_send("#{chave}_met_at")
    estourou = aplicado.breached_metrics.include?(chave) || (cumprido.present? && cumprido > prazo)
    lista = [evento(aplicado, base, 'apply_sla', aplicado.created_at, alvo: alvo(aplicado, prazo))]
    lista << evento(aplicado, base, 'fulfill', cumprido) if cumprido.present? && !estourou
    lista << evento(aplicado, base, 'breach', prazo) if estourou
    lista
  end

  def evento(aplicado, base, tipo, momento, alvo: nil)
    identidade = "#{aplicado.id}#{base[:instance_id]}#{tipo.hash.abs % 1000}".to_i
    base.merge(id: identidade, type: tipo, time: momento.utc.iso8601, deleted: false).tap { |dados| dados[:sla] = alvo if alvo }
  end

  def alvo(aplicado, prazo)
    minutos = ((prazo - aplicado.created_at) / 60).round
    { target: minutos, business_hours: aplicado.sla_policy&.calendar_id.present?, target_in_seconds: minutos * 60,
      policy: { id: aplicado.sla_policy_id, title: aplicado.sla_policy&.name } }
  end
end

# Avaliações de satisfação no formato do Zendesk, com paginação por cursor.
class Staydesk::Zendesk::SatisfactionRatingsController < Staydesk::Zendesk::BaseController
  ESCOPO = 'relatorios'.freeze

  def index
    tamanho = params.dig(:page, :size).to_i.clamp(1, 100)
    respostas, tem_mais = pagina(tamanho)
    proxima = tem_mais ? proxima_url(tamanho, respostas.last.id) : nil
    render json: {
      satisfaction_ratings: respostas.map { |resposta| serializador.avaliacao(resposta) },
      meta: { has_more: tem_mais, after_cursor: respostas.last&.id&.to_s },
      links: { next: proxima }, next_page: proxima, count: respostas.size
    }
  end

  private

  def pagina(tamanho)
    escopo = CsatSurveyResponse.where(account_id: conta.id).includes(:conversation).order(:created_at, :id)
                               .where(created_at: unix(params[:start_time], Time.zone.at(0))..)
    depois = params.dig(:page, :after)
    escopo = escopo.where('csat_survey_responses.id > ?', depois.to_i) if depois.present?
    respostas = escopo.limit(tamanho + 1).to_a
    [respostas.first(tamanho), respostas.size > tamanho]
  end

  def proxima_url(tamanho, ultimo_id)
    url_for(only_path: false, params: request.query_parameters.merge(page: { size: tamanho, after: ultimo_id }))
  end
end

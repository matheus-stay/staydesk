# Os números da operação num lugar só: CSAT, tempos por fila, fila de espera e
# agentes. Serve a Central, o dashboard e o MCP com a mesma conta.
class Api::V1::Accounts::Staydesk::KpisController < Api::V1::Accounts::Staydesk::BaseController
  JANELA_MAXIMA = 366.days

  before_action { check_authorization(Staydesk::Kpi) }

  # `compare=1` traz também o período anterior de mesma duração, para o desvio.
  def index
    @kpis = Staydesk::KpiService.new(account: Current.account, since: desde, ate: ate, filtros: filtros).perform
    return if params[:compare].blank?

    duracao = ate - desde
    @kpis[:anterior] = Staydesk::KpiService.new(account: Current.account, since: desde - duracao, ate: desde, filtros: filtros).resumo
  end

  private

  # Recortes: agente, canal de trabalho (chave) e grupo.
  def filtros
    params.permit(:user_id, :load_queue, :team_id).to_h
  end

  def desde
    valor = params[:since].present? ? Time.zone.parse(params[:since].to_s) : 7.days.ago
    [valor || 7.days.ago, ate - JANELA_MAXIMA].max
  end

  def ate
    @ate ||= (params[:until].present? ? Time.zone.parse(params[:until].to_s) : nil) || Time.current
  end
end

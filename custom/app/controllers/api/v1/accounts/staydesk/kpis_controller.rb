# Os números da operação num lugar só: CSAT, tempos por fila, fila de espera e
# agentes. Serve a Central, o dashboard e o MCP com a mesma conta.
class Api::V1::Accounts::Staydesk::KpisController < Api::V1::Accounts::Staydesk::BaseController
  JANELA_MAXIMA = 366.days

  before_action { check_authorization(Staydesk::Kpi) }

  def index
    @kpis = Staydesk::KpiService.new(account: Current.account, since: desde, ate: ate).perform
  end

  private

  def desde
    valor = params[:since].present? ? Time.zone.parse(params[:since].to_s) : 7.days.ago
    [valor || 7.days.ago, ate - JANELA_MAXIMA].max
  end

  def ate
    @ate ||= (params[:until].present? ? Time.zone.parse(params[:until].to_s) : nil) || Time.current
  end
end

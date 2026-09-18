# Indicador de aceitação por agente (SPEC-16), para a coordenação e para o dashboard.
class Api::V1::Accounts::Staydesk::OfferStatsController < Api::V1::Accounts::Staydesk::BaseController
  before_action { authorize(Staydesk::AgentStatus, :loads?) }

  def index
    desde = params[:since].present? ? Time.zone.parse(params[:since]) : 7.days.ago
    ate = params[:until].present? ? Time.zone.parse(params[:until]) : Time.current
    @stats = Staydesk::OfferStatsService.new(Current.account, since: desde, until_time: ate).perform
  end
end

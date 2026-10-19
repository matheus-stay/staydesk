# Diagnóstico da distribuição: quem recebe o quê, e o que falta para quem não recebe.
class Api::V1::Accounts::Staydesk::DistributionChecksController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::DistributionCheck) }

  # Com `conversation_id`, em vez do quadro por agente, o caminho daquela
  # conversa pela distribuição, etapa por etapa, até onde ela para.
  def index
    if params[:conversation_id].present?
      conversa = Current.account.conversations.find(params[:conversation_id])
      return render(json: Staydesk::DistributionTrace.new(conversa).perform)
    end

    @checks = Staydesk::DistributionCheckService.new(Current.account).perform
  end
end

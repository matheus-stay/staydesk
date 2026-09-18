# Diagnóstico da distribuição: quem recebe o quê, e o que falta para quem não recebe.
class Api::V1::Accounts::Staydesk::DistributionChecksController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::DistributionCheck) }

  def index
    @checks = Staydesk::DistributionCheckService.new(Current.account).perform
  end
end

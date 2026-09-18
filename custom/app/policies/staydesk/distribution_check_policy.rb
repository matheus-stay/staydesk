# O diagnóstico da distribuição é de quem configura status e filas.
class Staydesk::DistributionCheckPolicy < ApplicationPolicy
  include Staydesk::AreaDeConfiguracao
  configura_a_area :status

  def index?
    configura? || @account_user.staydesk_can?('staydesk_queues_manage')
  end
end

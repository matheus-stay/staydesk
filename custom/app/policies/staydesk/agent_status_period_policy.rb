class Staydesk::AgentStatusPeriodPolicy < ApplicationPolicy
  include Staydesk::AreaDeConfiguracao
  configura_a_area :status

  def index?
    configura?
  end

  def create?
    true
  end

  def offline?
    true
  end

  def leave?
    true
  end
end

class Staydesk::CapacityRulePolicy < ApplicationPolicy
  include Staydesk::AreaDeConfiguracao
  configura_a_area :filas

  def index?
    true
  end

  def create?
    configura?
  end

  def update?
    configura?
  end

  def destroy?
    configura?
  end
end

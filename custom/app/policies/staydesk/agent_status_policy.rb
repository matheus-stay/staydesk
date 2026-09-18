class Staydesk::AgentStatusPolicy < ApplicationPolicy
  include Staydesk::AreaDeConfiguracao
  configura_a_area :status

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

  def loads?
    configura?
  end
end

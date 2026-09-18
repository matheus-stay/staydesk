class Staydesk::CalendarPolicy < ApplicationPolicy
  include Staydesk::AreaDeConfiguracao
  configura_a_area :sla

  def index?
    true
  end

  def show?
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

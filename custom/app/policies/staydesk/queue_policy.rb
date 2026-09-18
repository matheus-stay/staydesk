class Staydesk::QueuePolicy < ApplicationPolicy
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

  def reorder?
    configura?
  end
end

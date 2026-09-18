class Staydesk::TicketStatusPolicy < ApplicationPolicy
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

  def reorder?
    configura?
  end

  def apply?
    true
  end
end

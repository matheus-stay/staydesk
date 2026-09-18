class Staydesk::RolePolicy < ApplicationPolicy
  include Staydesk::AreaDeConfiguracao
  configura_a_area :papeis

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

class Staydesk::AccountUserRolePolicy < ApplicationPolicy
  include Staydesk::AreaDeConfiguracao
  configura_a_area :papeis

  def index?
    configura?
  end

  def update?
    configura?
  end
end

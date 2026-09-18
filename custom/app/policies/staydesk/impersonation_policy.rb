class Staydesk::ImpersonationPolicy < ApplicationPolicy
  include Staydesk::AreaDeConfiguracao
  configura_a_area :papeis

  def index?
    configura?
  end

  def create?
    configura?
  end
end

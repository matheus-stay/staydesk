class Staydesk::AppliedSlaPolicy < ApplicationPolicy
  include Staydesk::AreaDeConfiguracao
  configura_a_area :sla

  def index?
    configura?
  end

  def show?
    true
  end
end

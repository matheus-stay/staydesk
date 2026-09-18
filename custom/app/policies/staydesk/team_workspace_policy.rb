class Staydesk::TeamWorkspacePolicy < ApplicationPolicy
  include Staydesk::AreaDeConfiguracao
  configura_a_area :visualizacoes

  def index?
    configura?
  end

  def show?
    configura?
  end

  def update?
    configura?
  end

  def schema?
    configura?
  end
end

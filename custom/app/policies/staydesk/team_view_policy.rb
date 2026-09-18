class Staydesk::TeamViewPolicy < ApplicationPolicy
  include Staydesk::AreaDeConfiguracao
  configura_a_area :visualizacoes

  def index?
    true
  end

  def show?
    true
  end

  def conversations?
    true
  end

  def counts?
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

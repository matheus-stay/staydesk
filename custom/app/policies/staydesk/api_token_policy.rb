# Token de API é chave da conta: só quem administra, ou quem tem a permissão de
# papéis, cria e revoga.
class Staydesk::ApiTokenPolicy < ApplicationPolicy
  include Staydesk::AreaDeConfiguracao
  configura_a_area :papeis

  def index?
    configura?
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

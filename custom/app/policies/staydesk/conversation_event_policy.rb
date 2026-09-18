class Staydesk::ConversationEventPolicy < ApplicationPolicy
  include Staydesk::AreaDeConfiguracao
  configura_a_area :relatorios

  def index?
    configura?
  end
end

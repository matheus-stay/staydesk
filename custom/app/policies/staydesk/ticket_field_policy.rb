# Ler os campos é de quem atende; mudar o catálogo é configuração.
class Staydesk::TicketFieldPolicy < ApplicationPolicy
  include Staydesk::AreaDeConfiguracao
  configura_a_area :status

  def index?
    true
  end

  def show?
    true
  end

  # Preencher campo de uma conversa é trabalho de atendimento, não configuração.
  def update?
    true
  end
end

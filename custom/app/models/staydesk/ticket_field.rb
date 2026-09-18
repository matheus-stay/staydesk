# Não é tabela: os campos do ticket vivem em CustomAttributeDefinition. Existe
# para o Pundit ter o que autorizar.
class Staydesk::TicketField
  def self.policy_class
    Staydesk::TicketFieldPolicy
  end
end

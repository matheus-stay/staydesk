# Não é tabela: existe para o Pundit ter o que autorizar no diagnóstico.
class Staydesk::DistributionCheck
  def self.policy_class
    Staydesk::DistributionCheckPolicy
  end
end

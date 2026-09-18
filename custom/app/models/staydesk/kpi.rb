# Não é tabela: existe para o Pundit ter o que autorizar nos números da operação.
class Staydesk::Kpi
  def self.policy_class
    Staydesk::KpiPolicy
  end
end

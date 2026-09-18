# Entra em AutomationRule pelo gancho prepend_mod_with: a automação passa a aceitar
# as ações da camada StayDesk, além das do produto.
module Custom::AutomationRule
  def actions_attributes
    super + Custom::Macro::STAYDESK_ACTIONS
  end
end

# Entra em AutomationRule pelo gancho prepend_mod_with: a automação passa a aceitar
# as ações da camada StayDesk, além das do produto.
module Custom::AutomationRule
  # Ações que só existem no gatilho, não na macro: o aviso de recebimento é
  # disparado pela chegada do chamado, não por alguém apertando um botão.
  ACOES_DO_GATILHO = %w[staydesk_aviso_de_recebimento].freeze

  def actions_attributes
    super + Custom::Macro::STAYDESK_ACTIONS + ACOES_DO_GATILHO
  end
end

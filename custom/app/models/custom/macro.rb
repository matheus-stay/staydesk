# Entra em Macro pelo gancho prepend_mod_with: a macro passa a aceitar as ações da
# camada StayDesk, além das do produto.
module Custom::Macro
  # As ações que a camada acrescenta, usadas também pelas automações.
  STAYDESK_ACTIONS = %w[staydesk_set_attribute staydesk_set_ticket_status].freeze

  private

  def json_actions_format
    return if actions.blank?

    nomes = actions.map { |acao, _| acao['action_name'] }
    desconhecidas = nomes - Macro::ACTIONS_ATTRS - STAYDESK_ACTIONS
    errors.add(:actions, "Macro execution actions #{desconhecidas.join(',')} not supported.") if desconhecidas.any?
  end
end

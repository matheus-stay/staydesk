# Entra em Message pelo gancho prepend_mod_with('Message'): o agente leve só
# cria nota privada. A API é a barreira; a interface só evita o erro.
module Custom::Message
  def self.prepended(base)
    base.validate :staydesk_light_sender_writes_private_notes_only, on: :create
  end

  private

  def staydesk_light_sender_writes_private_notes_only
    return if private || !sender.is_a?(User)

    account_user = account.account_users.find_by(user_id: sender_id)
    return unless account_user&.staydesk_light?

    errors.add(:private, 'light agents can only create private notes')
  end
end

# Entra em Conversation pelo gancho prepend_mod_with('Conversation').
module Custom::Conversation
  def self.prepended(base)
    base.after_update_commit :staydesk_record_events
    base.after_update_commit :staydesk_align_ticket_status
    base.has_one :staydesk_applied_sla, class_name: 'Staydesk::AppliedSla', dependent: :destroy
  end

  private

  # O status base mudou (botão, automação, bot): o status personalizado acompanha.
  def staydesk_align_ticket_status
    return unless saved_changes.key?('status')
    return unless Staydesk::TicketStatus.active.exists?(account_id: account_id)

    Staydesk::TicketStatusService.new(self).align_with_base!
  end

  def staydesk_record_events
    Staydesk::ConversationEvent::TRACKED.each do |attribute, kind|
      next unless saved_changes.key?(attribute)

      from_value, to_value = saved_changes[attribute]
      Staydesk::ConversationEvent.create!(
        account_id: account_id, conversation_id: id, kind: kind,
        from_value: from_value&.to_s, to_value: to_value&.to_s,
        user_id: Current.user.is_a?(User) ? Current.user.id : nil,
        created_at: Time.current
      )
    end
  end
end

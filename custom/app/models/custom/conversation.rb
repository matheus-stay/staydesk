# Entra em Conversation pelo gancho prepend_mod_with('Conversation').
module Custom::Conversation
  def self.prepended(base)
    base.after_update_commit :staydesk_record_events
    base.has_one :staydesk_applied_sla, class_name: 'Staydesk::AppliedSla', dependent: :destroy
  end

  private

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

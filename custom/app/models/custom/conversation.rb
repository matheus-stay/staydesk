# Entra em Conversation pelo gancho prepend_mod_with('Conversation').
module Custom::Conversation
  def self.prepended(base)
    base.validate :staydesk_required_ticket_fields
    base.after_create_commit :staydesk_route_to_queue
    base.after_update_commit :staydesk_offer_to_assignee
    base.after_update_commit :staydesk_record_events
    base.after_update_commit :staydesk_align_ticket_status
    base.after_update_commit :staydesk_status_on_assign
    base.has_one :staydesk_applied_sla, class_name: 'Staydesk::AppliedSla', dependent: :destroy
  end

  # Quem pode receber esta conversa: o grupo dono e, se ninguém dele estiver
  # disponível, o grupo de transbordo da fila (SPEC-15). A conversa não troca de grupo.
  def team_member_ids_with_capacity
    disponiveis = inbox.member_ids_with_assignment_capacity
    return super if team.blank? || team.allow_auto_assign.blank?

    Staydesk::QueueOverflow.new(self).eligible_user_ids(disponiveis)
  end

  private

  # Campo marcado como obrigatório precisa estar preenchido para resolver, como no
  # Zendesk. Vale para quem atende: automação, bot e resolução automática não
  # travam, senão a conversa fica presa sem ninguém para preencher.
  def staydesk_required_ticket_fields
    return unless status_changed? && resolved?
    return unless Current.user.is_a?(User)

    faltando = Staydesk::TicketFieldService.new(account).faltando(self)
    return if faltando.empty?

    errors.add(:status, I18n.t('staydesk.ticket_fields.required_to_resolve',
                               fields: faltando.map(&:attribute_display_name).join(', ')))
  end

  # Chat e WhatsApp são oferecidos: o agente precisa aceitar (SPEC-16).
  def staydesk_offer_to_assignee
    return unless saved_changes.key?('assignee_id') && assignee_id.present?

    Staydesk::OfferService.new(self).offer!(assignee)
  end

  # A conversa nova passa pelas filas antes de a distribuição escolher o agente
  # (SPEC-15). Roda no mesmo processo do commit, não em job, para chegar antes.
  def staydesk_route_to_queue
    Staydesk::QueueRouter.new(self).perform
  end

  # Atribuiu a alguém: o caso entra em andamento sozinho, como na operação.
  def staydesk_status_on_assign
    return unless saved_changes.key?('assignee_id')
    return unless Staydesk::TicketStatus.active.exists?(account_id: account_id, apply_on_assign: true)

    Staydesk::TicketStatusService.new(self).follow_assignment!
  end

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

# Entra em Conversation pelo gancho prepend_mod_with('Conversation').
module Custom::Conversation
  def self.prepended(base)
    base.validate :staydesk_required_ticket_fields
    base.after_create_commit :staydesk_route_to_queue
    # Um despacho só: os after_commit rodam em ordem inversa e alguns deles
    # salvam a conversa de novo, o que zera `saved_changes` para os seguintes
    # (o convite de aceite deixava de ser criado). A foto das mudanças é tirada
    # uma vez e passada a todos, na ordem certa.
    base.after_update_commit :staydesk_after_update
    base.has_one :staydesk_applied_sla, class_name: 'Staydesk::AppliedSla', dependent: :destroy
  end

  # Quem pode receber esta conversa: os grupos principais da fila e, se ninguém
  # deles estiver disponível, os secundários (SPEC-15).
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

  def staydesk_after_update
    mudancas = saved_changes.to_h
    staydesk_offer_to_assignee(mudancas)
    staydesk_follow_assignee_team(mudancas)
    staydesk_status_on_assign(mudancas)
    staydesk_record_events(mudancas)
    staydesk_align_ticket_status(mudancas)
  end

  # Chat e WhatsApp são oferecidos: o agente precisa aceitar (SPEC-16).
  def staydesk_offer_to_assignee(mudancas)
    return unless mudancas.key?('assignee_id') && assignee_id.present?

    Staydesk::OfferService.new(self).offer!(assignee)
  end

  # A conversa nova passa pelas filas antes de a distribuição escolher o agente
  # (SPEC-15). Roda no mesmo processo do commit, não em job, para chegar antes.
  def staydesk_route_to_queue
    Staydesk::QueueRouter.new(self).perform
  end

  # Como no Zendesk, a conversa fica no grupo de quem pegou: entregue a alguém de
  # outro grupo principal, ou de um secundário, ela passa para o grupo dele.
  def staydesk_follow_assignee_team(mudancas)
    return unless mudancas.key?('assignee_id') && assignee_id.present? && team_id.present?
    return if TeamMember.exists?(team_id: team_id, user_id: assignee_id)

    destino = staydesk_grupo_do_responsavel
    update!(team_id: destino) if destino.present?
  end

  # Dos grupos da fila que responde por este grupo, o primeiro em que o responsável está.
  def staydesk_grupo_do_responsavel
    fila = Staydesk::Queue.da_equipe(account_id, team_id)
    return if fila.blank?

    (fila.team_ids + fila.fallback_team_ids).find { |id| TeamMember.exists?(team_id: id, user_id: assignee_id) }
  end

  # Atribuiu a alguém: o caso entra em andamento sozinho, como na operação. Se a
  # fila exige aceite, isso espera o agente aceitar (Staydesk::OfferService).
  def staydesk_status_on_assign(mudancas)
    return unless mudancas.key?('assignee_id')
    return unless Staydesk::TicketStatus.active.exists?(account_id: account_id, apply_on_assign: true)
    return if assignee_id.present? && Staydesk::Offer.pendentes.exists?(conversation_id: id, user_id: assignee_id)

    Staydesk::TicketStatusService.new(self).follow_assignment!
  end

  # O status base mudou (botão, automação, bot): o status personalizado acompanha.
  def staydesk_align_ticket_status(mudancas)
    return unless mudancas.key?('status')
    return unless Staydesk::TicketStatus.active.exists?(account_id: account_id)

    Staydesk::TicketStatusService.new(self).align_with_base!
  end

  def staydesk_record_events(mudancas)
    Staydesk::ConversationEvent::TRACKED.each do |attribute, kind|
      next unless mudancas.key?(attribute)

      from_value, to_value = mudancas[attribute]
      Staydesk::ConversationEvent.create!(
        account_id: account_id, conversation_id: id, kind: kind,
        from_value: from_value&.to_s, to_value: to_value&.to_s,
        user_id: Current.user.is_a?(User) ? Current.user.id : nil,
        created_at: Time.current
      )
    end
  end
end

# Liga os eventos do Chatwoot ao motor de SLA. Registrado em Custom::AsyncDispatcher.
class Staydesk::SlaListener < BaseListener
  def conversation_created(event)
    conversation = event.data[:conversation]
    Staydesk::Sla::Applier.new(conversation).perform
  end

  def conversation_updated(event)
    conversation = event.data[:conversation]
    changed = (event.data[:changed_attributes] || {}).keys.map(&:to_s)
    return if (changed & %w[inbox_id priority custom_attributes team_id]).empty?
    return if changed == ['custom_attributes'] && sla_only_change?(event.data[:changed_attributes])

    Staydesk::Sla::Tracker.new(conversation).reevaluate
  end

  def conversation_status_changed(event)
    conversation = event.data[:conversation]
    previous, current = Array(event.data.dig(:changed_attributes, :status))
    Staydesk::Sla::Tracker.new(conversation).status_changed(previous.to_s, current.presence || conversation.status)
  end

  def message_created(event)
    message = event.data[:message]
    return if message.blank?

    Staydesk::Sla::Tracker.new(message.conversation).message_created(message)
  end

  private

  def sla_only_change?(changed_attributes)
    before, after = Array(changed_attributes[:custom_attributes] || changed_attributes['custom_attributes'])
    (before || {}).except('sla_alvo', 'sla_status', 'sla_vence_em') == (after || {}).except('sla_alvo', 'sla_status', 'sla_vence_em')
  end
end

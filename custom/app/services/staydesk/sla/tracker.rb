# Reage ao que acontece na conversa: cumpre métricas, pausa e retoma, reinicia a
# próxima resposta, encerra na resolução, e mantém os atributos do selo em dia.
class Staydesk::Sla::Tracker
  def initialize(conversation)
    @conversation = conversation
  end

  def applied
    @applied ||= Staydesk::AppliedSla.find_by(conversation: @conversation)
  end

  def message_created(message)
    return if applied.nil? || message.private? || message.activity?

    now = message.created_at
    if message.incoming?
      start_next_response(now)
    elsif message.outgoing? && message.sender.is_a?(User)
      applied.first_response_met_at ||= now
      applied.next_response_met_at = now if applied.next_response_due_at.present?
      applied.next_response_due_at = nil
    end
    finish(now)
  end

  def status_changed(previous_status, current_status, at = Time.current)
    return if applied.nil?

    policy = applied.sla_policy
    pausing = policy.pause_statuses.include?(current_status)
    if current_status == 'resolved'
      applied.resolution_met_at ||= at
      applied.next_response_due_at = nil
      applied.paused_at = nil
      applied.status = 'met' if applied.breached_metrics.empty?
      applied.status = 'breached' if applied.breached_metrics.any?
    elsif pausing && !applied.paused?
      applied.paused_at = at
      applied.status = 'paused'
    elsif !pausing && applied.paused?
      resume(at)
    elsif previous_status == 'resolved' && current_status == 'open'
      reopen(at)
    end
    finish(at)
  end

  def reevaluate
    Staydesk::Sla::Applier.new(@conversation).perform
  end

  def sync_attributes(applied_sla = applied)
    return if applied_sla.nil?

    attributes = (@conversation.custom_attributes || {}).merge(applied_sla.conversation_attributes)
    return if attributes == @conversation.custom_attributes

    # update! publica conversation.updated (selo ao vivo, webhooks); o listener ignora a mudança só de SLA.
    @conversation.update!(custom_attributes: attributes)
  end

  private

  def start_next_response(now)
    return if applied.next_response_due_at.present? && applied.next_response_met_at.blank?

    minutes = applied.sla_policy.target_minutes('next_response', @conversation.priority || 'default')
    return if minutes.nil?

    applied.next_response_due_at = applied.sla_policy.clock.add_minutes(now, minutes)
    applied.next_response_met_at = nil
    applied.warned_metrics -= ['next_response']
  end

  # Ao retomar, os prazos ainda abertos avançam pelo tempo que ficou parado.
  def resume(at)
    paused = at - applied.paused_at
    applied.paused_seconds += paused.to_i
    applied.pending_metrics.each do |metric, due_at|
      applied.public_send("#{metric}_due_at=", due_at + paused)
    end
    applied.paused_at = nil
    applied.status = applied.breached_metrics.any? ? 'breached' : 'running'
  end

  def reopen(at)
    applied.resolution_met_at = nil
    applied.status = applied.breached_metrics.any? ? 'breached' : 'running'
    start_next_response(at)
  end

  def finish(at)
    applied.status = 'running' if applied.status == 'met' && applied.resolution_met_at.blank? && applied.breached_metrics.empty?
    applied.save! if applied.changed?
    sync_attributes
    at
  end
end

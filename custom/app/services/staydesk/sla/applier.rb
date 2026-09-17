# Cria ou reavalia o SLA aplicado de uma conversa e grava os atributos que o selo lê.
class Staydesk::Sla::Applier
  def initialize(conversation)
    @conversation = conversation
  end

  def perform
    policy = Staydesk::Sla::PolicyMatcher.new(@conversation).perform
    applied = Staydesk::AppliedSla.find_by(conversation: @conversation)

    if policy.nil?
      applied&.destroy!
      clear_attributes
      return nil
    end

    return applied if applied && applied.sla_policy_id == policy.id && applied.status != 'met'

    applied ||= Staydesk::AppliedSla.new(account: @conversation.account, conversation: @conversation)
    applied.sla_policy = policy
    applied.status = 'running'
    applied.breached_metrics = []
    applied.warned_metrics = []
    applied.paused_at = nil
    applied.paused_seconds = 0
    start = @conversation.created_at
    clock = policy.clock
    priority = @conversation.priority || 'default'
    applied.first_response_due_at = due(clock, policy, 'first_response', priority, start) if @conversation.first_reply_created_at.blank?
    applied.first_response_met_at = @conversation.first_reply_created_at
    applied.resolution_due_at = due(clock, policy, 'resolution', priority, start)
    applied.next_response_due_at = nil
    applied.save!
    Staydesk::Sla::Tracker.new(@conversation).sync_attributes(applied)
    applied
  end

  private

  def due(clock, policy, metric, priority, from)
    minutes = policy.target_minutes(metric, priority)
    minutes ? clock.add_minutes(from, minutes) : nil
  end

  def clear_attributes
    attributes = @conversation.custom_attributes || {}
    return unless attributes.key?('sla_status')

    @conversation.update!(custom_attributes: attributes.except('sla_alvo', 'sla_status', 'sla_vence_em'))
  end
end

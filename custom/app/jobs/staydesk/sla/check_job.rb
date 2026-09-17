# A cada minuto: marca aviso e violação nas métricas em andamento, grava o evento na
# linha do tempo da conversa e publica o evento para as automações. Uma vez por métrica.
class Staydesk::Sla::CheckJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Staydesk::AppliedSla.open.where(paused_at: nil).includes(:sla_policy, :conversation).find_each do |applied|
      check(applied)
    rescue StandardError => e
      Rails.logger.error("staydesk sla check failed for conversation #{applied.conversation_id}: #{e.message}")
    end
  end

  private

  def check(applied)
    now = Time.current
    policy = applied.sla_policy
    changed = false

    applied.pending_metrics.each do |metric, due_at|
      if due_at <= now && applied.breached_metrics.exclude?(metric)
        applied.breached_metrics += [metric]
        applied.status = 'breached'
        publish(applied, 'staydesk_sla.breached', metric)
        changed = true
      elsif due_at > now && applied.warned_metrics.exclude?(metric) && warning?(applied, policy, metric, due_at, now)
        applied.warned_metrics += [metric]
        applied.status = 'warning' if applied.status == 'running'
        publish(applied, 'staydesk_sla.warning', metric)
        changed = true
      end
    end
    return unless changed

    applied.save!
    Staydesk::Sla::Tracker.new(applied.conversation).sync_attributes(applied)
  end

  def warning?(applied, policy, metric, due_at, now)
    minutes = policy.target_minutes(metric, applied.conversation.priority || 'default')
    return false if minutes.nil?

    (due_at - now) <= (minutes * 60 * policy.warning_ratio.to_f)
  end

  def publish(applied, event_name, metric)
    conversation = applied.conversation
    Staydesk::ConversationEvent.create!(
      account_id: applied.account_id, conversation_id: conversation.id,
      kind: event_name.tr('.', '_'), from_value: applied.sla_policy.name, to_value: metric, created_at: Time.current
    )
    Rails.configuration.dispatcher.dispatch(event_name, Time.zone.now, conversation: conversation, metric: metric,
                                                                             applied_sla: applied)
  end
end

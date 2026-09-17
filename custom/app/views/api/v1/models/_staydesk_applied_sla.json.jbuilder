json.id resource.id
json.conversation_id resource.conversation.display_id
json.sla_policy_id resource.sla_policy_id
json.sla_policy_name resource.sla_policy.name
json.status resource.status
json.paused_at resource.paused_at
json.paused_seconds resource.paused_seconds
json.breached_metrics resource.breached_metrics
json.warned_metrics resource.warned_metrics
json.next_due_at resource.next_due_at
json.metrics do
  Staydesk::SlaPolicy::METRICS.each do |metric|
    json.set! metric do
      json.due_at resource.public_send("#{metric}_due_at")
      json.met_at resource.public_send("#{metric}_met_at")
      json.breached resource.breached_metrics.include?(metric)
    end
  end
end
json.created_at resource.created_at
json.updated_at resource.updated_at

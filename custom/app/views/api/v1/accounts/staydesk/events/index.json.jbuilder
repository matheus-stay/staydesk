conversation_display_ids = Conversation.where(id: (@reporting_events.map(&:conversation_id) + @conversation_events.map(&:conversation_id)).uniq)
                                       .pluck(:id, :display_id).to_h

json.reporting_events @reporting_events do |event|
  json.id event.id
  json.name event.name
  json.value event.value
  json.value_in_business_hours event.value_in_business_hours
  json.event_start_time event.event_start_time
  json.event_end_time event.event_end_time
  json.conversation_id conversation_display_ids[event.conversation_id]
  json.inbox_id event.inbox_id
  json.user_id event.user_id
  json.created_at event.created_at
end

json.conversation_events @conversation_events do |event|
  json.id event.id
  json.kind event.kind
  json.from event.from_value
  json.to event.to_value
  json.conversation_id conversation_display_ids[event.conversation_id]
  json.user_id event.user_id
  json.created_at event.created_at
end

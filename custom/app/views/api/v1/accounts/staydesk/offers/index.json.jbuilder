json.array! @offers do |offer|
  json.id offer.id
  json.status offer.status
  json.seconds_left offer.segundos_restantes
  json.conversation_id offer.conversation.display_id
  json.contact_name offer.conversation.contact&.name
  json.inbox_name offer.conversation.inbox&.name
  json.last_message offer.conversation.messages.incoming.last&.content
end

json.statuses @agent_statuses do |status|
  json.partial! 'api/v1/models/staydesk_agent_status', formats: [:json], resource: status
  json.available_to_me @liberados.include?(status.id)
end
json.current_status_id @current_status&.id

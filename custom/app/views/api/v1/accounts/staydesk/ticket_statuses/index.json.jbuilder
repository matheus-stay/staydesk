json.array! @ticket_statuses do |resource|
  json.partial! 'api/v1/models/staydesk_ticket_status', formats: [:json], resource: resource
end

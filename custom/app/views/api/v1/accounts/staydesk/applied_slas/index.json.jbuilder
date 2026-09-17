json.array! @applied_slas do |resource|
  json.partial! 'api/v1/models/staydesk_applied_sla', formats: [:json], resource: resource
end

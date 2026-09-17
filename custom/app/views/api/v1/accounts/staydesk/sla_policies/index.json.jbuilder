json.array! @sla_policies do |resource|
  json.partial! 'api/v1/models/staydesk_sla_policy', formats: [:json], resource: resource
end

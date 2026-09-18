json.array! @capacity_rules do |resource|
  json.partial! 'api/v1/models/staydesk_capacity_rule', formats: [:json], resource: resource
end

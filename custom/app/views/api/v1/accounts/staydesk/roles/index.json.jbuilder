json.permissions @permissions
json.roles @roles do |resource|
  json.partial! 'api/v1/models/staydesk_role', formats: [:json], resource: resource
end

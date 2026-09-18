json.ticket_fields @ticket_fields do |campo|
  json.partial! 'api/v1/models/custom_attribute_definition', formats: [:json], resource: campo
end

json.api_tokens @api_tokens do |api_token|
  json.partial! 'api/v1/models/staydesk_api_token', formats: [:json], resource: api_token
end
json.scopes @scopes

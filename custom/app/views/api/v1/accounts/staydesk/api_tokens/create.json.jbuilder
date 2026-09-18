json.partial! 'api/v1/models/staydesk_api_token', formats: [:json], resource: @api_token
# O valor em claro aparece uma vez só, aqui.
json.token @api_token.token_em_claro

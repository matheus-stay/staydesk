json.array! @team_views do |team_view|
  json.partial! 'api/v1/models/staydesk_team_view', formats: [:json], resource: team_view
end

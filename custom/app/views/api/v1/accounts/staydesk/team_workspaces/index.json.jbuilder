json.array! @team_workspaces do |team_workspace|
  json.partial! 'api/v1/models/staydesk_team_workspace', formats: [:json], resource: team_workspace
end

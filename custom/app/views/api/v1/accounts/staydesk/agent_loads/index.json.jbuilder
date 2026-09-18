json.array! @agents do |agent|
  entry = @summary[agent.id] || {}
  json.user_id agent.id
  json.name agent.name
  json.load entry[:load] || {}
  json.capacity entry[:capacity] || {}
  json.rule entry[:rule]&.name
  if entry[:status]
    json.status do
      json.partial! 'api/v1/models/staydesk_agent_status', formats: [:json], resource: entry[:status]
    end
  else
    json.status nil
  end
end

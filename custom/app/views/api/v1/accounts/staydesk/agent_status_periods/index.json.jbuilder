json.array! @periods do |period|
  json.id period.id
  json.user_id period.account_user.user_id
  json.agent_status_id period.agent_status_id
  json.agent_status_name period.agent_status.name
  json.started_at period.started_at
  json.ended_at period.ended_at
end

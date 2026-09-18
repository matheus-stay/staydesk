json.array! @impersonations do |resource|
  json.id resource.id
  json.created_at resource.created_at
  json.actor_name resource.actor.name
  json.target_name resource.target.name
  json.target_id resource.target_id
end

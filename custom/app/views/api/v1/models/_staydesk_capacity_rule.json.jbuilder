json.id resource.id
json.name resource.name
json.description resource.description
json.limits resource.limits
json.is_default resource.is_default
json.user_ids resource.user_ids
json.user_names resource.users.order(:name).pluck(:name)
json.position resource.position

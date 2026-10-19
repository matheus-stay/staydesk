json.array! @accounts do |account|
  json.id account.id
  json.name account.name
  json.locale account.locale
  json.status account.status
  json.created_at account.created_at.to_i
  json.agents_count account.account_users.count
end

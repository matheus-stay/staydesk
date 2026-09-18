json.array! @account_users do |account_user|
  json.user_id account_user.user_id
  json.name account_user.user.name
  json.email account_user.user.email
  json.role account_user.role
  json.kind account_user.staydesk_role&.kind || 'full'
  json.staydesk_role_id account_user.staydesk_role&.staydesk_role_id
  json.permissions account_user.permissions
end

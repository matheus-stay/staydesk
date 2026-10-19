json.account do
  json.id @resultado.account.id
  json.name @resultado.account.name
  json.locale @resultado.account.locale
end
json.admin do
  json.id @resultado.admin.id
  json.name @resultado.admin.name
  json.email @resultado.admin.email
end
json.login_url @resultado.admin.generate_sso_link
json.configuration @resultado.configuracao

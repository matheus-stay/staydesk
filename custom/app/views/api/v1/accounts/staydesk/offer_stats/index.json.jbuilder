json.array! @stats do |linha|
  json.user_id linha[:user_id]
  json.name linha[:name]
  json.offers linha[:offers]
  json.accepted linha[:accepted]
  json.declined linha[:declined]
  json.expired linha[:expired]
  json.acceptance_rate linha[:acceptance_rate]
  json.average_answer_seconds linha[:average_answer_seconds]
end

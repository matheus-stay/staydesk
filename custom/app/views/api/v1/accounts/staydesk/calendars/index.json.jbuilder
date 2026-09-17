json.array! @calendars do |resource|
  json.partial! 'api/v1/models/staydesk_calendar', formats: [:json], resource: resource
end

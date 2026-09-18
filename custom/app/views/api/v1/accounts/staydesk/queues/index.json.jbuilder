json.array! @queues do |resource|
  json.partial! 'api/v1/models/staydesk_queue', formats: [:json], resource: resource
end

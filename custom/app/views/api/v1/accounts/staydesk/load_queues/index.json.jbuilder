json.load_queues @load_queues do |load_queue|
  json.partial! 'api/v1/models/staydesk_load_queue', formats: [:json], resource: load_queue
end

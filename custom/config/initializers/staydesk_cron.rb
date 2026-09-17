# frozen_string_literal: true

# Job de checagem do SLA a cada minuto, fora do schedule.yml do núcleo.
Rails.application.reloader.to_prepare do
  next unless defined?(Sidekiq::Cron::Job) && Sidekiq.server?

  Sidekiq::Cron::Job.create(
    name: 'staydesk_sla_check_job', cron: '* * * * *', class: 'Staydesk::Sla::CheckJob', queue: 'scheduled_jobs', source: 'staydesk'
  )
end

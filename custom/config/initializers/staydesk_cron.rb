# frozen_string_literal: true

# Jobs de minuto do StayDesk, fora do schedule.yml do núcleo: checagem de SLA e
# varredura da fila.
Rails.application.reloader.to_prepare do
  next unless defined?(Sidekiq::Cron::Job) && Sidekiq.server?

  Sidekiq::Cron::Job.create(
    name: 'staydesk_sla_check_job', cron: '* * * * *', class: 'Staydesk::Sla::CheckJob', queue: 'scheduled_jobs', source: 'staydesk'
  )

  # A fila parada é oferecida de novo: quem entrou antes de o agente ficar
  # disponível não pode ficar esperando mensagem nova para ser distribuído.
  Sidekiq::Cron::Job.create(
    name: 'staydesk_queue_sweep_job', cron: '* * * * *', class: 'Staydesk::Queues::SweepJob', queue: 'scheduled_jobs', source: 'staydesk'
  )
end

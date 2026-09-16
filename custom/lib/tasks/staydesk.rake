# frozen_string_literal: true

namespace :staydesk do
  desc 'Aplica a configuração base do StayDesk: marca (InstallationConfig) e flags de conta'
  task setup: :environment do
    Staydesk::SetupService.new.perform
    puts "staydesk:setup — marca StayDesk aplicada; #{Staydesk::SetupService::ACCOUNT_FEATURES.join(', ')} em #{Account.count} conta(s)"
  end
end

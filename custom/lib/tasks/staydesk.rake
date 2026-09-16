# frozen_string_literal: true

namespace :staydesk do
  desc 'Aplica a configuração base do StayDesk: marca (InstallationConfig) e flags de conta'
  task setup: :environment do
    Staydesk::SetupService.new.perform
    puts "staydesk:setup — marca StayDesk aplicada; #{Staydesk::SetupService::ACCOUNT_FEATURES.join(', ')} em #{Account.count} conta(s)"
  end
end

namespace :staydesk do
  namespace :team_views do
    desc 'Importa views por time de um YAML: rails staydesk:team_views:importar ACCOUNT_ID=1 FILE=views.yml'
    task importar: :environment do
      account = Account.find(ENV.fetch('ACCOUNT_ID'))
      definitions = YAML.safe_load_file(ENV.fetch('FILE'))
      views = Staydesk::TeamViewImportService.new(account: account, definitions: definitions).perform
      puts "staydesk:team_views:importar — #{views.size} view(s) na conta #{account.id}"
    end
  end
end

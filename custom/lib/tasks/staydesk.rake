# frozen_string_literal: true

namespace :staydesk do
  desc 'Aplica a configuração base do StayDesk: marca (InstallationConfig) e flags de conta'
  task setup: :environment do
    Staydesk::SetupService.new.perform
    puts "staydesk:setup — marca StayDesk aplicada em #{Account.count} conta(s); " \
         "ligado: #{Staydesk::SetupService::ACCOUNT_FEATURES.join(', ')}; " \
         "desligado: #{Staydesk::SetupService::DISABLED_FEATURES.join(', ')}"
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

namespace :staydesk do
  desc 'Aplica a configuração da operação a partir de um YAML: rails staydesk:configurar ACCOUNT_ID=1 FILE=configuracao.yml'
  task configurar: :environment do
    account = Account.find(ENV.fetch('ACCOUNT_ID', 1))
    config = YAML.safe_load(File.read(ENV.fetch('FILE')), permitted_classes: [Date])
    resumo = Staydesk::ConfigImportService.new(account: account, config: config).perform
    puts JSON.pretty_generate(resumo)
  end
end

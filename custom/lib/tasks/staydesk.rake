# frozen_string_literal: true

namespace :staydesk do
  desc 'Aplica a configuração base do StayDesk em todas as contas (edição community)'
  task setup: :environment do
    Account.find_each { |account| account.enable_features!('disable_branding') }
    puts "staydesk:setup — disable_branding ligado em #{Account.count} conta(s)"
  end
end

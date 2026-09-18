namespace :staydesk do
  desc 'Popula a conta com dados fictícios (ACCOUNT_ID=1, RESET=1 limpa antes, SOMENTE=historico só o histórico do cliente)'
  task demo: :environment do
    abort 'staydesk:demo não roda em produção (use FORCE=1 se souber o que está fazendo).' if Rails.env.production? && ENV['FORCE'] != '1'

    conta = Account.find(ENV.fetch('ACCOUNT_ID', 1))
    semeador = Staydesk::DemoSeeder.new(account: conta, reset: ENV['RESET'] == '1')
    resumo = ENV['SOMENTE'] == 'historico' ? semeador.historico! : semeador.perform!
    puts JSON.pretty_generate(resumo)
  end
end

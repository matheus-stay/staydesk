# Aplica a configuração base do StayDesk: marca via InstallationConfig e flags de
# conta. Idempotente; roda em teste e em produção por `rails staydesk:setup`.
class Staydesk::SetupService
  BRAND_URL = ENV.fetch('STAYDESK_BRAND_URL', 'https://staycloud.com.br')

  BRANDING = {
    'INSTALLATION_NAME' => 'StayDesk',
    'BRAND_NAME' => 'StayDesk',
    'BRAND_URL' => BRAND_URL,
    'WIDGET_BRAND_URL' => BRAND_URL,
    'TERMS_URL' => ENV.fetch('STAYDESK_TERMS_URL', BRAND_URL),
    'PRIVACY_URL' => ENV.fetch('STAYDESK_PRIVACY_URL', BRAND_URL)
  }.freeze

  ACCOUNT_FEATURES = %w[disable_branding].freeze

  def perform
    BRANDING.each do |name, value|
      InstallationConfig.find_or_initialize_by(name: name).update!(value: value, locked: false)
    end
    Account.find_each { |account| account.enable_features!(*ACCOUNT_FEATURES) }
  end
end

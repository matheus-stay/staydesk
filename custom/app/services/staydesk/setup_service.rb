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

  # Recursos que a operação não usa: saem das contas existentes e do padrão que
  # vale para conta nova (a lista do produto fica intacta).
  DISABLED_FEATURES = %w[campaigns help_center].freeze

  # Papéis prontos para começar; o resto a operação cria na tela.
  BUILT_IN_ROLES = [
    { name: 'Supervisor', description: 'Atende e vê os relatórios de todo o time', permissions: %w[report_manage] },
    { name: 'Agente com meus números', description: 'Atende e vê apenas os próprios números', permissions: %w[staydesk_report_own] }
  ].freeze

  def perform
    BRANDING.each do |name, value|
      InstallationConfig.find_or_initialize_by(name: name).update!(value: value, locked: false)
    end
    aplicar_nas_contas
    aplicar_no_padrao_de_conta_nova
    criar_papeis_prontos
  end

  private

  def criar_papeis_prontos
    Account.find_each do |account|
      BUILT_IN_ROLES.each_with_index do |dados, indice|
        papel = Staydesk::Role.find_or_initialize_by(account: account, name: dados[:name])
        next if papel.persisted?

        papel.update!(description: dados[:description], permissions: dados[:permissions], built_in: true, position: indice)
      end
    end
  end

  def aplicar_nas_contas
    Account.find_each do |account|
      account.enable_features(*ACCOUNT_FEATURES)
      account.disable_features(*DISABLED_FEATURES)
      account.save!
    end
  end

  # O padrão de conta nova mora numa InstallationConfig que o Chatwoot reconcilia
  # com config/features.yml no boot, preservando o valor já gravado.
  def aplicar_no_padrao_de_conta_nova
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    return if config.blank?

    valor = config.value.map do |feature|
      DISABLED_FEATURES.include?(feature['name']) ? feature.merge('enabled' => false) : feature
    end
    config.update!(value: valor)
  end
end

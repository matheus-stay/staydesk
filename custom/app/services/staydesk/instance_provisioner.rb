# Instância nova do StayDesk numa operação só: a conta no padrão StayDesk (sem a
# marca do produto, sem campanhas e central de ajuda, com os papéis prontos), o
# administrador e, se vier, a configuração da operação (o mesmo YAML do
# config_import). É o que a superadministração chama para gerar instância nova.
class Staydesk::InstanceProvisioner
  Resultado = Struct.new(:account, :admin, :configuracao, keyword_init: true)

  def initialize(conta:, admin:, configuracao: nil)
    @conta = conta.to_h.symbolize_keys
    @admin = admin.to_h.symbolize_keys
    @configuracao = configuracao
  end

  def perform
    ActiveRecord::Base.transaction do
      account = Account.create!(name: @conta.fetch(:name), locale: @conta[:locale].presence || 'pt_BR',
                                support_email: @conta[:support_email])
      Staydesk::SetupService.new.preparar_conta(account)
      admin = administrador(account)
      Resultado.new(account: account, admin: admin, configuracao: aplicar_configuracao(account))
    end
  end

  private

  # Quem já tem usuário (outra instância, por exemplo) é só vinculado.
  def administrador(account)
    email = @admin.fetch(:email).to_s.downcase
    usuario = User.from_email(email) || User.new(name: @admin.fetch(:name), email: email,
                                                 password: @admin[:password].presence || senha_provisoria)
    usuario.skip_confirmation!
    usuario.save!
    AccountUser.find_or_create_by!(account: account, user: usuario) { |vinculo| vinculo.role = :administrator }
    usuario
  end

  def aplicar_configuracao(account)
    return if @configuracao.blank?

    config = @configuracao.is_a?(String) ? YAML.safe_load(@configuracao, permitted_classes: [Date]) : @configuracao.to_h
    Staydesk::ConfigImportService.new(account: account, config: config).perform
  end

  # Sem senha informada, o administrador entra pelo link de acesso devolvido e
  # troca a senha no perfil.
  def senha_provisoria
    "#{SecureRandom.base58(20)}aA1!"
  end
end

# Superadministração por API: listar e gerar instâncias (contas) do StayDesk.
# Autentica como a Platform API do produto: token de um "Platform App" criado no
# super admin, no cabeçalho `api_access_token`. A instância criada passa a ser
# administrável por esse app na Platform API (contas, usuários, vínculos).
class Platform::Api::V1::Staydesk::InstancesController < PlatformController
  def index
    @accounts = @platform_app.platform_app_permissibles.where(permissible_type: 'Account').includes(:permissible).map(&:permissible)
  end

  def create
    @resultado = Staydesk::InstanceProvisioner.new(conta: params.require(:account).permit(:name, :locale, :support_email),
                                                   admin: params.require(:admin).permit(:name, :email, :password),
                                                   configuracao: configuracao).perform
    @platform_app.platform_app_permissibles.find_or_create_by!(permissible: @resultado.account)
    @platform_app.platform_app_permissibles.find_or_create_by!(permissible: @resultado.admin)
    render :create, status: :created
  end

  private

  # A configuração da operação vem como texto YAML (`config_yaml`) ou já em
  # JSON (`config`), como no config_import.
  def configuracao
    return params[:config_yaml] if params[:config_yaml].present?

    params[:config]&.to_unsafe_h
  end
end

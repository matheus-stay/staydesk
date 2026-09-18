# Aplica a configuração da operação inteira de uma vez, a mesma que o comando
# `rails staydesk:configurar` lê de um YAML. Serve para subir um ambiente novo
# (staging, uma conta nova) sem console: manda o arquivo e a conta fica pronta.
class Api::V1::Accounts::Staydesk::ConfigImportsController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::ConfigImportService) }

  def create
    resumo = Staydesk::ConfigImportService.new(account: Current.account, config: configuracao).perform
    render json: resumo
  rescue Psych::SyntaxError => e
    render json: { message: "YAML inválido: #{e.message}" }, status: :unprocessable_entity
  end

  private

  # Aceita o YAML como texto (`yaml`) ou a mesma estrutura já em JSON (`config`).
  def configuracao
    return YAML.safe_load(params[:yaml].to_s, permitted_classes: [Date]) || {} if params[:yaml].present?

    params.require(:config).to_unsafe_h
  end
end

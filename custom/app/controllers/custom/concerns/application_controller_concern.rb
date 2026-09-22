# Entra em ApplicationController pelo gancho include_mod_with('Concerns::ApplicationControllerConcern').
# Guarda central do agente leve: fora das leituras, só passa o que está na lista.
module Custom::Concerns::ApplicationControllerConcern
  extend ActiveSupport::Concern

  LIGHT_WRITE_ALLOWLIST = {
    'api/v1/accounts/conversations/messages' => %w[create],
    'api/v1/accounts/conversations' => %w[update_last_seen toggle_typing_status unread],
    'api/v1/accounts/notifications' => %w[update read_all destroy],
    'api/v1/accounts/notification_subscriptions' => %w[create destroy],
    'api/v1/accounts/custom_filters' => %w[create update destroy],
    'api/v1/profiles' => %w[update availability auto_offline set_active_account avatar]
  }.freeze

  # Relatórios: quem só tem os próprios números não pode pedir os dos outros.
  REPORT_CONTROLLERS = %r{\Aapi/v2/accounts/reports}

  included do
    before_action :staydesk_guard_light_agent
    before_action :staydesk_guard_own_reports
  end

  private

  # Papel com `staydesk_report_own` e sem `report_manage` só enxerga a si mesmo:
  # o pedido precisa vir filtrado pelo próprio usuário.
  def staydesk_guard_own_reports
    return if staydesk_fora_do_alcance_da_guarda?
    return unless REPORT_CONTROLLERS.match?(controller_path)
    return unless staydesk_report_limited_to_self?
    return if staydesk_report_about_self?

    render json: { error: 'This role only sees its own numbers' }, status: :forbidden
  end

  # Verdadeiro quando o papel dá `staydesk_report_own` e não dá `report_manage`.
  def staydesk_report_limited_to_self?
    return false unless respond_to?(:current_user, true) && current_user.is_a?(User)

    account_user = staydesk_request_account_user
    return false if account_user.nil? || account_user.administrator?

    permissoes = account_user.staydesk_permissions
    permissoes.include?('staydesk_report_own') && permissoes.exclude?('report_manage')
  end

  def staydesk_report_about_self?
    escopo = params[:type].to_s
    alvo = params[:id].presence || params[:user_id].presence
    return false if escopo.present? && escopo != 'agent'

    alvo.to_s == current_user.id.to_s
  end

  def staydesk_guard_light_agent
    return if request.get? || request.head?
    return if staydesk_fora_do_alcance_da_guarda?
    return unless staydesk_light_account_user?
    return if LIGHT_WRITE_ALLOWLIST.fetch(controller_path, []).include?(action_name) && staydesk_light_message_allowed?

    render json: { error: 'Light agents can only read and add private notes' }, status: :forbidden
  end

  # Entrar, sair, confirmar conta e trocar senha são rotas de autenticação: não
  # há agente leve antes de existir sessão, e perguntar por `current_user` ali
  # quebra o fluxo do produto — era o 500 de quem tentava definir a senha.
  def staydesk_fora_do_alcance_da_guarda?
    respond_to?(:devise_controller?, true) && devise_controller?
  end

  def staydesk_light_account_user?
    return false unless respond_to?(:current_user, true) && current_user.is_a?(User)

    staydesk_request_account_user&.staydesk_light?
  end

  # A conta em jogo na requisição: a do escopo da rota, a da própria rota de conta
  # (/api/v1/accounts/:id) ou, fora de rota de conta, a única conta do usuário.
  # Sem conta identificada, a guarda não opina: o usuário não é tratado como leve.
  def staydesk_request_account_user
    account_id = params[:account_id].presence
    account_id ||= params[:id].presence if controller_path == 'api/v1/accounts'
    return current_user.account_users.find_by(account_id: account_id) if account_id.present?

    account_users = current_user.account_users.limit(2).to_a
    account_users.size == 1 ? account_users.first : nil
  end

  def staydesk_light_message_allowed?
    return true unless controller_path == 'api/v1/accounts/conversations/messages'

    ActiveModel::Type::Boolean.new.cast(params[:private])
  end
end

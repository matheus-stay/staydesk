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
    'api/v1/profile' => %w[update availability auto_offline set_active_account avatar]
  }.freeze

  included do
    before_action :staydesk_guard_light_agent
  end

  private

  def staydesk_guard_light_agent
    return if request.get? || request.head?
    return unless staydesk_light_account_user?
    return if LIGHT_WRITE_ALLOWLIST.fetch(controller_path, []).include?(action_name) && staydesk_light_message_allowed?

    render json: { error: 'Light agents can only read and add private notes' }, status: :forbidden
  end

  def staydesk_light_account_user?
    return false unless respond_to?(:current_user, true) && current_user.is_a?(User)

    account_id = params[:account_id] || current_user.account_id
    account_id.present? && current_user.account_users.find_by(account_id: account_id)&.staydesk_light?
  end

  def staydesk_light_message_allowed?
    return true unless controller_path == 'api/v1/accounts/conversations/messages'

    ActiveModel::Type::Boolean.new.cast(params[:private])
  end
end

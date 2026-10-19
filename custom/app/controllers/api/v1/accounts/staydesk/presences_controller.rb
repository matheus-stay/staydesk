# Sinal de vida do agente por HTTP. O front atual manda pelo WebSocket
# (RoomChannel#update_presence, a cada 20 s); um front que não use o WebSocket
# chama isto no mesmo ritmo. Sem o sinal, o tempo limite do status e a saída ao
# fechar a aba tiram o agente do status, e a distribuição para de entregar.
class Api::V1::Accounts::Staydesk::PresencesController < Api::V1::Accounts::Staydesk::BaseController
  def create
    OnlineStatusTracker.update_presence(Current.account.id, 'User', Current.user.id)
    status = Staydesk::AgentStatusService.new(Current.account_user).current
    render json: { online: true, current_status_id: status&.id, availability: Current.account_user.availability,
                   valid_for_seconds: OnlineStatusTracker::PRESENCE_DURATION.to_i }
  end
end

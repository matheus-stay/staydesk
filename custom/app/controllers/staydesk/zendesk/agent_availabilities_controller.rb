# Disponibilidade dos agentes no formato JSON:API do Zendesk: o catálogo de
# status e o status de cada agente agora, com os canais (support = ticket,
# messaging = chat).
class Staydesk::Zendesk::AgentAvailabilitiesController < Staydesk::Zendesk::BaseController
  ESCOPO = 'relatorios'.freeze

  def statuses
    dados = Staydesk::AgentStatus.active.where(account_id: conta.id).ordered.map do |status|
      { id: status.id.to_s, type: 'agent_status', attributes: { name: status.name, channels: canais(status), default: false } }
    end
    render json: { data: padrao + dados }
  end

  def index
    conectados = (OnlineStatusTracker.get_available_users(conta.id) || {}).select { |_id, estado| estado == 'online' }.keys.map(&:to_i)
    dados = conta.account_users.includes(:user).map do |vinculo|
      status = Staydesk::AgentStatusService.new(vinculo).current
      atual = status_atual(status, conectados.include?(vinculo.user_id))
      { id: "agent_availabilities|#{vinculo.user_id}", type: 'agent_availability',
        attributes: { agent_id: vinculo.user_id, agent_status: atual, agent_status_id: atual[:id], channels: atual[:channels] } }
    end
    render json: { data: dados, links: { next: nil } }
  end

  private

  def padrao
    [
      { id: 'online', type: 'agent_status',
        attributes: { name: 'Online', channels: { support: 'online', messaging: 'online', talk: 'offline' }, default: true } },
      { id: 'offline', type: 'agent_status',
        attributes: { name: 'Offline', channels: { support: 'offline', messaging: 'offline', talk: 'offline' }, default: true } }
    ]
  end

  def canais(status)
    recebe = status.availability == 'online' ? status.work_channels : []
    { support: recebe.include?('ticket') ? 'online' : 'offline', messaging: recebe.include?('chat') ? 'online' : 'offline', talk: 'offline' }
  end

  # Sem status personalizado: conectado é "Online", senão "Offline".
  def status_atual(status, conectado)
    if status
      { id: status.id.to_s, name: status.name, updated_at: Time.current.utc.iso8601, channels: canais(status) }
    elsif conectado
      { id: 'online', name: 'Online', updated_at: Time.current.utc.iso8601, channels: padrao.first[:attributes][:channels] }
    else
      { id: 'offline', name: 'Offline', updated_at: Time.current.utc.iso8601, channels: padrao.last[:attributes][:channels] }
    end
  end
end

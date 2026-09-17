# Painel de carga (SPEC-11): quantas conversas cada agente atende agora em cada
# fila, contra o limite do status em que ele está.
class Api::V1::Accounts::Staydesk::AgentLoadsController < Api::V1::Accounts::Staydesk::BaseController
  before_action { authorize(Staydesk::AgentStatus, :loads?) }

  def index
    @agents = Current.account.users.order(:name)
    @summary = Staydesk::AgentLoadService.new(Current.account).summary(@agents.map(&:id))
  end
end

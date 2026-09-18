# Grupos no formato do Zendesk: os times da conta.
class Staydesk::Zendesk::GroupsController < Staydesk::Zendesk::BaseController
  ESCOPO = 'relatorios'.freeze

  def index
    grupos = conta.teams.order(:name).map { |time| serializador.grupo(time) }
    render json: { groups: grupos, next_page: nil, count: grupos.size }
  end
end

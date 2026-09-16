# Administração das áreas de trabalho por time. `default` como :team_id é o padrão da conta.
class Api::V1::Accounts::Staydesk::TeamWorkspacesController < Api::V1::Accounts::Staydesk::BaseController
  before_action { check_authorization(Staydesk::TeamWorkspace) }
  before_action :fetch_team_workspace, only: [:show, :update]

  def index
    @team_workspaces = Staydesk::TeamWorkspace.where(account: Current.account).order(Arel.sql('team_id NULLS FIRST'))
  end

  def show; end

  def update
    @team_workspace.update!(config: params.require(:config).permit!.to_h)
  end

  def schema
    render json: Staydesk::TeamWorkspace.schema
  end

  private

  def fetch_team_workspace
    team_id = params[:team_id] == 'default' ? nil : Current.account.teams.find(params[:team_id]).id
    @team_workspace = Staydesk::TeamWorkspace.find_or_initialize_by(account: Current.account, team_id: team_id)
  end
end

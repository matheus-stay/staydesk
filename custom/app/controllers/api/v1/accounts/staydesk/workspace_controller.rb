# A área de trabalho já resolvida para quem chama (qualquer papel).
class Api::V1::Accounts::Staydesk::WorkspaceController < Api::V1::Accounts::Staydesk::BaseController
  def show
    area_de_trabalho = Staydesk::WorkspaceResolver.new(user: Current.user, account: Current.account).resolve
    render json: area_de_trabalho.merge('can_manage' => pode_configurar)
  end

  private

  # Quais áreas da Central quem chama pode configurar, pela mesma regra que o
  # servidor aplica (Staydesk::AreaDeConfiguracao): o front só mostra o que vale.
  def pode_configurar
    areas = Staydesk::Role.catalogo.pluck('area').compact.uniq
    areas.index_with do |area|
      Current.account_user.administrator? ||
        Staydesk::Role.permissions_for_area(area).intersect?(Current.account_user.staydesk_permissions)
    end
  end
end

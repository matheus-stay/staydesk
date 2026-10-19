# Quem fecha a aba sai do status na hora, sem esperar o tempo limite dele: o
# combinado é que só volta a receber quem escolher um status de novo. O aviso
# chega quando a aba fecha, mas F5 e uma segunda aba aberta também avisam;
# por isso o job espera a presença expirar (o navegador renova a cada 20s e ela
# vale 20s) e só desliga se não sobrou nenhuma aba conectada.
class Staydesk::AgentStatuses::LeaveJob < ApplicationJob
  queue_as :default

  ESPERA = 45.seconds

  def perform(account_user_id)
    account_user = AccountUser.find_by(id: account_user_id)
    return if account_user.blank?

    periodo = Staydesk::AgentStatusPeriod.current.includes(:agent_status).find_by(account_user: account_user)
    return if periodo.blank?
    return if OnlineStatusTracker.get_presence(account_user.account_id, 'User', account_user.user_id)

    Staydesk::AgentStatusService.new(account_user).desconectar!(periodo)
  end
end

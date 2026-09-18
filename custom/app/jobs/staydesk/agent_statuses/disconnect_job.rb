# Quem fechou a aba não está atendendo, mas o status ficava gravado como se
# estivesse, e o tempo online seguia contando. A cada minuto, quem está
# conectado tem a presença carimbada no período; quem passou do tempo limite do
# status é desligado: o período fecha, a disponibilidade vai a offline e, se o
# status tiver um destino, o agente cai nele.
class Staydesk::AgentStatuses::DisconnectJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Staydesk::AgentStatusPeriod.current.includes(:agent_status, account_user: :account).find_each do |periodo|
      servico = Staydesk::AgentStatusService.new(periodo.account_user)
      if conectado?(periodo)
        servico.registrar_presenca!(periodo)
      elsif servico.passou_do_limite?(periodo)
        servico.desconectar!(periodo)
      end
    end
  end

  private

  def conectado?(periodo)
    conta = periodo.account_user.account_id
    OnlineStatusTracker.get_presence(conta, 'User', periodo.account_user.user_id)
  end
end

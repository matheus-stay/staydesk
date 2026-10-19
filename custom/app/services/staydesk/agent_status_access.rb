# Que status cada agente pode escolher, pelas filas dos grupos dele
# (Staydesk::AgentStatus#liberado_para?). Administrador escolhe qualquer um, e
# conta sem fila ativa não tem restrição.
class Staydesk::AgentStatusAccess
  def initialize(account_user)
    @account_user = account_user
  end

  def liberado?(status)
    return true if livre?

    status.liberado_para?(canais)
  end

  def ids_liberados(statuses)
    statuses.select { |status| liberado?(status) }.map(&:id)
  end

  private

  def livre?
    @account_user.administrator? || !membership.com_filas?
  end

  def canais
    @canais ||= membership.canais_de_trabalho(@account_user.user_id)
  end

  def membership
    @membership ||= Staydesk::QueueMembership.new(@account_user.account)
  end
end

# Só o administrador aplica a configuração inteira: ela mexe em times, status,
# SLA, filas e área de trabalho de uma vez.
class Staydesk::ConfigImportServicePolicy < ApplicationPolicy
  def create?
    @account_user.administrator?
  end
end

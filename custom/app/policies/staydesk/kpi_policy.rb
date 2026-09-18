# Os números do time são de quem administra ou de quem tem relatório do time.
# Quem só vê os próprios números não lê este endpoint.
class Staydesk::KpiPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.staydesk_can?('report_manage')
  end
end

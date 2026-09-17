class Staydesk::AgentStatusPeriodPolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end

  def create?
    true
  end
end

class Staydesk::TeamWorkspacePolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end

  def show?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def schema?
    @account_user.administrator?
  end
end

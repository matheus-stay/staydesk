class Staydesk::AppliedSlaPolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end

  def show?
    true
  end
end

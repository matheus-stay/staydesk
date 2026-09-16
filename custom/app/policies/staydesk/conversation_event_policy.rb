class Staydesk::ConversationEventPolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end
end

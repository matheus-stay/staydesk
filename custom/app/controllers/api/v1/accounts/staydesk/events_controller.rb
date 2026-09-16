# Eventos de tempo (reporting_events) e de mudança (staydesk_conversation_events)
# para o dashboard sincronizar só pela API. Paginação por id em cada lista.
class Api::V1::Accounts::Staydesk::EventsController < Api::V1::Accounts::Staydesk::BaseController
  MAX_LIMIT = 500

  before_action { check_authorization(Staydesk::ConversationEvent) }

  def index
    @reporting_events = paginate(reporting_events_scope, params[:after_reporting_id])
    @conversation_events = paginate(conversation_events_scope, params[:after_event_id])
  end

  private

  def limit
    [params.fetch(:limit, MAX_LIMIT).to_i, MAX_LIMIT].min
  end

  def paginate(scope, after_id)
    scope = scope.where('id > ?', after_id) if after_id.present?
    scope.order(:id).limit(limit)
  end

  def reporting_events_scope
    scope = ReportingEvent.where(account_id: Current.account.id)
    scope = scope.where(name: params[:kind]) if params[:kind].present?
    within_window(with_conversation(scope))
  end

  def conversation_events_scope
    scope = Staydesk::ConversationEvent.where(account: Current.account)
    scope = scope.where(kind: params[:kind]) if params[:kind].present?
    within_window(with_conversation(scope))
  end

  def with_conversation(scope)
    return scope if params[:conversation_id].blank?

    conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
    scope.where(conversation_id: conversation.id)
  end

  def within_window(scope)
    scope = scope.where(created_at: DateTime.parse(params[:since])..) if params[:since].present?
    scope = scope.where(created_at: ..DateTime.parse(params[:until])) if params[:until].present?
    scope
  end
end

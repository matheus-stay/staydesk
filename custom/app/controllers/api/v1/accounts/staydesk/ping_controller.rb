class Api::V1::Accounts::Staydesk::PingController < Api::V1::Accounts::Staydesk::BaseController
  def show
    render json: { staydesk: Staydesk::VERSION, chatwoot: Chatwoot.config[:version] }
  end
end

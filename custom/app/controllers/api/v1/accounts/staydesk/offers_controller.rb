# Convites de atendimento do próprio agente (SPEC-16).
class Api::V1::Accounts::Staydesk::OffersController < Api::V1::Accounts::Staydesk::BaseController
  before_action :fetch_offer, only: [:accept, :decline]

  # O convite pendente de quem está pedindo, se houver.
  def index
    @offer = Staydesk::Offer.pendentes
                            .where(account_id: Current.account.id, user_id: current_user.id)
                            .where(expires_at: Time.current..)
                            .includes(conversation: [:contact, :inbox]).order(created_at: :desc).first
  end

  def accept
    Staydesk::OfferService.new(@offer.conversation).accept!(@offer)
    render :show
  end

  def decline
    Staydesk::OfferService.new(@offer.conversation).decline!(@offer)
    render :show
  end

  private

  def fetch_offer
    @offer = Staydesk::Offer.where(account_id: Current.account.id, user_id: current_user.id).find(params[:id])
  end
end

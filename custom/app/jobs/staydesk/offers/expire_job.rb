# Convite que não foi respondido no tempo volta para a fila (SPEC-16).
class Staydesk::Offers::ExpireJob < ApplicationJob
  queue_as :low

  def perform(offer_id)
    convite = Staydesk::Offer.find_by(id: offer_id)
    return if convite.blank? || !convite.pendente? || convite.expires_at > Time.current

    Staydesk::OfferService.new(convite.conversation).decline!(convite, status: 'expirada')
  end
end

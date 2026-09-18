# Aceitação do agente (SPEC-16): quantos convites ele recebeu, quantos aceitou e
# em quanto tempo. É o indicador que a coordenação olha para saber quem está
# realmente pegando o chat quando ele chega.
class Staydesk::OfferStatsService
  def initialize(account, since: 7.days.ago, until_time: Time.current)
    @account = account
    @since = since
    @until = until_time
  end

  def perform
    convites = Staydesk::Offer.where(account_id: @account.id, created_at: @since..@until)
    por_agente = convites.group(:user_id, :status).count
    tempos = tempo_medio(convites)

    @account.users.order(:name).map { |user| linha(user, por_agente, tempos) }
  end

  private

  def linha(user, por_agente, tempos)
    contagem = ->(status) { por_agente[[user.id, status]].to_i }
    ofertas = Staydesk::Offer::STATUSES.sum { |status| contagem.call(status) }
    aceitas = contagem.call('aceita')

    {
      user_id: user.id, name: user.name, offers: ofertas, accepted: aceitas,
      declined: contagem.call('recusada'), expired: contagem.call('expirada'),
      acceptance_rate: ofertas.zero? ? nil : (aceitas * 100.0 / ofertas).round(1),
      average_answer_seconds: tempos[user.id]&.round
    }
  end

  def tempo_medio(convites)
    convites.where(status: 'aceita').where.not(answered_at: nil)
            .group(:user_id)
            .average(Arel.sql('EXTRACT(EPOCH FROM (answered_at - created_at))'))
            .transform_values(&:to_f)
  end
end

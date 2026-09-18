# Convites perdidos (SPEC-16, no modelo do Zendesk): quem deixa vencer ou recusa
# N convites seguidos não está na frente da tela. Cai para o status que a regra
# de capacidade dele diz (ou fica sem status), para de contar tempo online, e
# os convites que ainda estavam com ele voltam para a fila.
class Staydesk::MissedOffersService
  def initialize(account, user_id)
    @account = account
    @user_id = user_id
  end

  # Chamado depois de cada convite não aceito. Devolve o status novo quando derruba.
  def verificar!
    regra = Staydesk::CapacityRule.for_user(@account, @user_id)
    return unless regra&.derruba_por_convites?
    return unless vinculo && recebendo?
    return unless perdeu_seguidos?(regra.missed_offers_limit)

    afastar(regra)
  end

  private

  def vinculo
    @vinculo ||= @account.account_users.find_by(user_id: @user_id)
  end

  # Só derruba quem está num status que recebe; quem já está ausente fica como está.
  def recebendo?
    Staydesk::AgentStatusService.new(vinculo).current&.availability == 'online'
  end

  # Os últimos N convites respondidos desde que o agente entrou no status atual,
  # todos não aceitos. Convite ainda pendente não conta.
  def perdeu_seguidos?(limite)
    desde = Staydesk::AgentStatusPeriod.current.find_by(account_user_id: vinculo.id)&.started_at || Time.zone.at(0)
    ultimos = Staydesk::Offer.where(account_id: @account.id, user_id: @user_id)
                             .where.not(status: 'pendente').where(created_at: desde..)
                             .order(created_at: :desc).limit(limite).pluck(:status)
    ultimos.size == limite && ultimos.none?('aceita')
  end

  def afastar(regra)
    destino = regra.missed_offers_to_status
    Staydesk::AgentStatusService.new(vinculo).afastar!(destino)
    devolver_convites_pendentes
    destino
  end

  def devolver_convites_pendentes
    Staydesk::Offer.pendentes.where(account_id: @account.id, user_id: @user_id).find_each do |convite|
      Staydesk::OfferService.new(convite.conversation).decline!(convite, status: 'expirada')
    end
  end
end

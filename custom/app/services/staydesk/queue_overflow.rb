# Quem pode pegar a conversa, no modelo do Zendesk: primeiro quem está nos grupos
# principais da fila; se nenhum deles tem gente disponível (e a espera passou),
# quem está nos grupos secundários. A conversa entra no primeiro grupo principal
# e, quando alguém pega, passa para o grupo desse agente (Custom::Conversation).
class Staydesk::QueueOverflow
  def initialize(conversation)
    @conversation = conversation
  end

  # Dos agentes que já poderiam receber nesta caixa, quem realmente entra na roda.
  def eligible_user_ids(available_user_ids)
    return available_user_ids if @conversation.team_id.blank?

    principais = Staydesk::Queue.membros(grupos_principais) & available_user_ids
    return principais if principais.any?
    return principais unless transbordo_liberado?

    Staydesk::Queue.membros(fila.fallback_team_ids) & available_user_ids
  end

  def transbordo_teams
    fila&.fallback_teams || Team.none
  end

  private

  def fila
    return @fila if defined?(@fila)

    @fila = Staydesk::Queue.da_equipe(@conversation.account_id, @conversation.team_id)
  end

  # Sem fila para o grupo, o grupo da conversa é o único principal.
  def grupos_principais
    fila ? fila.team_ids : [@conversation.team_id]
  end

  # Sem espera configurada os secundários entram na hora; com espera, só depois dela.
  def transbordo_liberado?
    return false if fila.blank? || fila.fallback_team_ids.empty?
    return true if fila.fallback_after_minutes.blank?

    @conversation.created_at <= fila.fallback_after_minutes.minutes.ago
  end
end

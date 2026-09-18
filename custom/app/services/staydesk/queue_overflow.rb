# Transbordo de fila (SPEC-15), no modelo da operação: o trabalho é do grupo dono
# (todo chat é do N1, todo ticket é do N2 ou N3) e isso não muda. O que muda é quem
# pode atender: sem ninguém disponível no grupo dono, os agentes do grupo de
# transbordo entram na distribuição, sem que a conversa troque de grupo.
class Staydesk::QueueOverflow
  def initialize(conversation)
    @conversation = conversation
  end

  # Dos agentes que já poderiam receber nesta caixa, quem realmente entra na roda.
  def eligible_user_ids(available_user_ids)
    time = @conversation.team
    disponiveis = available_user_ids
    return disponiveis if time.blank?

    do_grupo = time.members.ids & disponiveis
    # Grupo que ajuda sempre trabalha a fila junto com o dono.
    return (do_grupo + (transbordo_ids & disponiveis)).uniq if ajuda_sempre?
    return do_grupo if do_grupo.any?
    return do_grupo unless transbordo_liberado?

    transbordo_ids & disponiveis
  end

  def transbordo_teams
    fila&.fallback_teams || Team.none
  end

  def ajuda_sempre?
    fila.present? && fila.fallback_mode == 'sempre' && transbordo_teams.any?
  end

  private

  def fila
    @fila ||= Staydesk::Queue.with_fallback
                             .where(account_id: @conversation.account_id, team_id: @conversation.team_id)
                             .ordered.first
  end

  def transbordo_ids
    transbordo_teams.flat_map { |time| time.members.ids }.uniq
  end

  # Sem espera configurada o transbordo vale na hora; com espera, só depois dela.
  def transbordo_liberado?
    return false if transbordo_teams.empty?
    return true if fila.fallback_after_minutes.blank?

    @conversation.created_at <= fila.fallback_after_minutes.minutes.ago
  end
end

# "Está na fila e ninguém recebe": refaz, sem mudar nada, o caminho que a
# varredura (Staydesk::Queues::SweepJob) e a distribuição do Chatwoot fazem com
# uma conversa, e diz em que etapa ela para. `para_em` nulo é que a conversa
# deveria ser oferecida a quem aparece em `escolheria`.
class Staydesk::DistributionTrace
  def initialize(conversation)
    @conversa = conversation
    @caixa = conversation.inbox
  end

  def perform
    etapas = da_conversa + da_roda
    { conversation_id: @conversa.id, para_em: etapas.find { |etapa| !etapa[:ok] }&.dig(:etapa), etapas: etapas }
  end

  private

  # O que a conversa precisa ter para a varredura sequer tentar.
  def da_conversa
    [
      etapa('aberta_sem_responsavel', @conversa.open? && @conversa.assignee_id.nil?, status: @conversa.status),
      # O Chatwoot pula sem aviso a conversa que está com um bot.
      etapa('sem_bot_responsavel', @conversa.assignee_agent_bot_id.nil?, assignee_agent_bot_id: @conversa.assignee_agent_bot_id),
      etapa('sem_convite_pendente', pendentes.none?, pendentes: pendentes.map { |c| c.slice(:id, :user_id, :expires_at) })
    ] + do_roteamento
  end

  def do_roteamento
    [
      etapa('distribuicao_ligada_no_canal', @caixa.enable_auto_assignment?, inbox_id: @caixa.id),
      etapa('tem_grupo', @conversa.team_id.present?, team_id: @conversa.team_id),
      etapa('tem_fila', fila.present?, fila: fila&.name, exige_aceite: fila&.accept_required)
    ]
  end

  def fila
    @fila ||= Staydesk::Queue.da_conversa(@conversa)
  end

  def pendentes
    @pendentes ||= Staydesk::Offer.pendentes.where(conversation_id: @conversa.id).to_a
  end

  # Quem pode receber, filtro a filtro, na ordem da distribuição.
  def da_roda
    na_roda = @caixa.member_ids_with_assignment_capacity
    elegiveis = Staydesk::QueueOverflow.new(@conversa).eligible_user_ids(na_roda)
    candidatos = online & elegiveis.map(&:to_s)
    [
      etapa('alguem_na_roda_do_canal', na_roda.any?, membros: @caixa.inbox_members.pluck(:user_id), com_vaga: na_roda),
      etapa('alguem_elegivel_na_fila', elegiveis.any?, elegiveis: elegiveis),
      etapa('alguem_online_entre_os_elegiveis', candidatos.any?, online: online, candidatos: candidatos),
      etapa('rodizio_tem_o_candidato', rodizio.intersect?(candidatos), rodizio: rodizio, escolheria: (rodizio & candidatos).last)
    ]
  end

  def online
    @online ||= (OnlineStatusTracker.get_available_users(@conversa.account_id) || {}).select { |_id, estado| estado == 'online' }.keys
  end

  # O rodízio do Chatwoot se refaz com os membros do canal quando o Redis não
  # bate com eles; é com essa lista que a escolha acontece.
  def rodizio
    @rodizio ||= begin
      guardado = ::Redis::Alfred.lrange(format(::Redis::Alfred::ROUND_ROBIN_AGENTS, inbox_id: @caixa.id))
      membros = @caixa.inbox_members.map(&:user_id)
      membros.sort == guardado.map(&:to_i).sort ? guardado : membros.map(&:to_s)
    end
  end

  def etapa(nome, passou, detalhes = {})
    { etapa: nome, ok: passou ? true : false }.merge(detalhes)
  end
end

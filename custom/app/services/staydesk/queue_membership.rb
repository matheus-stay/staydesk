# Quem atende cada canal sai das filas, como no Zendesk: a fila diz que canais
# pega e que grupos atendem, e quem está num desses grupos (principal ou
# secundário) atende aqueles canais. O Chatwoot, por baixo, só entrega e só
# mostra a conversa de um canal a quem é membro dele; por isso os membros de
# cada canal são calculados daqui e não escolhidos à mão.
#
# Só age em conta que tem fila ativa: sem fila, os canais ficam como estão.
class Staydesk::QueueMembership
  def self.sync!(account)
    new(account).sync!
  end

  def initialize(account)
    @account = account
  end

  # Acerta os membros de cada canal. Devolve quantos vínculos entraram e saíram.
  def sync!
    return { adicionados: 0, removidos: 0 } if filas.empty?

    @account.inboxes.includes(:inbox_members).each_with_object({ adicionados: 0, removidos: 0 }) do |canal, total|
      quer = membros_por_canal.fetch(canal.id, [])
      tem = canal.inbox_members.map(&:user_id)
      (quer - tem).each { |user_id| canal.inbox_members.create!(user_id: user_id) }
      canal.inbox_members.where(user_id: tem - quer).destroy_all
      total[:adicionados] += (quer - tem).size
      total[:removidos] += (tem - quer).size
    end
  end

  # Para cada canal, os agentes da conta que estão em algum grupo de alguma fila
  # que pega o canal, mais quem está com uma conversa aberta dele: quem recebeu
  # por transferência continua enxergando o que é seu.
  def membros_por_canal
    @membros_por_canal ||= begin
      mapa = pelas_filas
      responsaveis.each { |(canal_id, user_id)| mapa[canal_id] |= [user_id] }
      grupos_com_conversa.each { |canal_id, agentes| mapa[canal_id] |= agentes }
      mapa
    end
  end

  # Os canais de trabalho (chat, ticket…) que o agente atende pelas filas dos
  # grupos dele. É o que decide que status ele pode escolher.
  def canais_de_trabalho(user_id)
    filas.select { |fila| Staydesk::Queue.membros(fila.team_ids + fila.fallback_team_ids).include?(user_id) }
         .flat_map { |fila| chaves_da_fila(fila) }.uniq
  end

  def com_filas?
    filas.any?
  end

  private

  def filas
    @filas ||= Staydesk::Queue.active.where(account: @account).to_a
  end

  def pelas_filas
    filas.each_with_object(Hash.new { |hash, id| hash[id] = [] }) do |fila, mapa|
      agentes = Staydesk::Queue.membros(fila.team_ids + fila.fallback_team_ids) & agentes_da_conta
      @account.inboxes.select { |canal| fila.atende_canal?(canal) }.each { |canal| mapa[canal.id] |= agentes }
    end
  end

  def chaves_da_fila(fila)
    return fila.load_queue_keys if fila.load_queue_keys.present?

    @account.inboxes.select { |canal| fila.atende_canal?(canal) }.filter_map { |canal| Staydesk::LoadQueue.for_inbox(canal)&.key }
  end

  # Conversa mandada a um grupo fora das filas (comercial, financeiro, o
  # ticket de plugin que vai ao N1) fica visível a quem está nele enquanto aberta.
  def grupos_com_conversa
    pares = @account.conversations.where.not(status: :resolved).where.not(team_id: nil).distinct.pluck(:inbox_id, :team_id)
    membros = TeamMember.where(team_id: pares.map(&:last).uniq).pluck(:team_id, :user_id).group_by(&:first)
    pares.each_with_object(Hash.new { |hash, id| hash[id] = [] }) do |(canal_id, time_id), mapa|
      mapa[canal_id] |= (membros[time_id] || []).map(&:last) & agentes_da_conta
    end
  end

  def responsaveis
    @account.conversations.where.not(status: :resolved).where.not(assignee_id: nil)
            .where(assignee_id: agentes_da_conta).distinct.pluck(:inbox_id, :assignee_id)
  end

  def agentes_da_conta
    @agentes_da_conta ||= @account.account_users.pluck(:user_id)
  end
end

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

  # Para cada canal, os agentes da conta que estão em algum grupo de alguma fila que pega o canal.
  def membros_por_canal
    @membros_por_canal ||= filas.each_with_object(Hash.new { |hash, id| hash[id] = [] }) do |fila, mapa|
      agentes = Staydesk::Queue.membros(fila.team_ids + fila.fallback_team_ids) & agentes_da_conta
      @account.inboxes.select { |canal| fila.atende_canal?(canal) }.each { |canal| mapa[canal.id] |= agentes }
    end
  end

  private

  def filas
    @filas ||= Staydesk::Queue.active.where(account: @account).to_a
  end

  def agentes_da_conta
    @agentes_da_conta ||= @account.account_users.pluck(:user_id)
  end
end

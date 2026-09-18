# No Zendesk não existe "membro da caixa": quem está no grupo atende o canal que
# a fila mandar. Aqui a regra é a mesma, por cima do Chatwoot: todo agente da
# conta está em todos os canais, sempre. Quem recebe o quê é decidido por grupo,
# status, capacidade e conexão, e o que o agente vê, pelas visualizações e papéis.
class Staydesk::ChannelMembership
  def self.sync!(account)
    new(account).sync!
  end

  def initialize(account)
    @account = account
  end

  # Coloca em cada canal quem ainda não está. Devolve quantos vínculos criou.
  def sync!
    agentes = @account.account_users.pluck(:user_id)
    @account.inboxes.includes(:inbox_members).sum do |canal|
      faltando = agentes - canal.inbox_members.map(&:user_id)
      faltando.each { |user_id| canal.inbox_members.create!(user_id: user_id) }
      faltando.size
    end
  end
end

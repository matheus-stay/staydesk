# Entra na Inbox pelo gancho prepend_mod_with: a distribuição automática legada
# pergunta quem ainda tem vaga, e quem bateu o limite do próprio status sai da lista.
module Custom::Inbox
  def self.prepended(base)
    base.after_create_commit :staydesk_add_everyone
  end

  # Canal novo já nasce com todos os agentes da conta, como no Zendesk
  # (Staydesk::ChannelMembership). O assistente do Chatwoot ainda pergunta quem
  # adicionar; quem já está entra sem erro.
  def add_members(user_ids)
    super(user_ids.map(&:to_i) - inbox_members.pluck(:user_id))
  end

  # A fila com aceite (SPEC-16) vive na distribuição legada: é ela que chama
  # `find_assignee`, guarda o convidado e dispara o convite. A distribuição v2 do
  # upstream é assíncrona, passa por um job por caixa e, quando ligada, desvia o
  # fluxo inteiro — a conversa entra na fila, ninguém é convidado e nada registra
  # erro. Enquanto o aceite for o nosso modelo, a caixa fica no caminho legado,
  # independente de a conta ter a chave `assignment_v2` ligada.
  def auto_assignment_v2_enabled?
    false
  end

  def member_ids_with_assignment_capacity
    ids = super & conectados_agora
    return ids if ids.blank?

    Staydesk::AgentLoadService.new(account).with_capacity(self, ids)
  end

  private

  def staydesk_add_everyone
    account.account_users.pluck(:user_id).each { |user_id| inbox_members.find_or_create_by!(user_id: user_id) }
  end

  # Quem tem conexão viva agora. O Chatwoot só entrega a quem está conectado, mas
  # só checa isso no fim: sem cortar aqui, o grupo dono parece cheio de gente, o
  # transbordo nunca abre e a conversa fica esperando por quem não está atendendo.
  def conectados_agora
    presentes = OnlineStatusTracker.get_available_users(account_id) || {}
    presentes.select { |_id, estado| estado == 'online' }.keys.map(&:to_i)
  end
end

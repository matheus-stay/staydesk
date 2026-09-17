# Entra na Inbox pelo gancho prepend_mod_with: a distribuição automática legada
# pergunta quem ainda tem vaga, e quem bateu o limite do próprio status sai da lista.
module Custom::Inbox
  def member_ids_with_assignment_capacity
    ids = super
    return ids if ids.blank?

    Staydesk::AgentLoadService.new(account).with_capacity(self, ids)
  end
end

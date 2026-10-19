# Entra no controller de atribuíveis pelo gancho prepend_mod_with. No Zendesk a
# conversa pode ser mandada a qualquer agente; no Chatwoot a lista sai só de
# quem é membro do canal, e no StayDesk isso vem das filas. Para transferir a
# alguém de fora da fila (o ticket que alguém manda ao N1), a lista é a conta.
module Custom::Api::V1::Accounts::AssignableAgentsController
  def index
    super
    @assignable_agents = Current.account.users.order(:name).to_a
  end
end

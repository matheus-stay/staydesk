# Usuários no formato do Zendesk: agentes e administradores da conta; a busca
# por e-mail também encontra contatos (usuários finais).
class Staydesk::Zendesk::UsersController < Staydesk::Zendesk::BaseController
  ESCOPO = 'relatorios'.freeze

  def index
    usuarios = conta.users.includes(:account_users).order(:name).map { |user| serializador.usuario(user) }
    papeis = Array(params[:role]).presence
    usuarios = usuarios.select { |usuario| papeis.include?(usuario[:role]) } if papeis
    render json: { users: usuarios, next_page: nil, previous_page: nil, count: usuarios.size }
  end

  def search
    consulta = params[:query].to_s.strip.downcase
    contatos = conta.contacts.where('lower(email) = ?', consulta).limit(20).map { |contato| serializador.usuario_final(contato) }
    agentes = conta.users.where('lower(email) = ?', consulta).map { |user| serializador.usuario(user) }
    render json: { users: agentes + contatos, next_page: nil, count: agentes.size + contatos.size }
  end
end

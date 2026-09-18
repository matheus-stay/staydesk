# Tickets no formato do Zendesk: exportação incremental por cursor (o que o
# sync do dashboard usa), leitura, comentários, tags e atualização.
class Staydesk::Zendesk::TicketsController < Staydesk::Zendesk::BaseController
  ESCOPO = 'conversas'.freeze
  POR_PAGINA_MAXIMO = 1000

  # GET incremental/tickets/cursor.json?start_time=&cursor=&include=metric_sets,users,groups&per_page=
  def incremental
    por_pagina = params[:per_page].to_i.clamp(1, POR_PAGINA_MAXIMO)
    conversas, fim = pagina(por_pagina)
    tickets = conversas.map { |conversa| serializador.ticket(conversa) }
    ultima = conversas.last
    resposta = { tickets: tickets, after_cursor: ultima && cursor_de(ultima), before_cursor: nil,
                 end_of_stream: fim, end_time: (ultima&.updated_at || Time.current).to_i, count: tickets.size }
    render json: resposta.merge(inclusoes(conversas, tickets))
  end

  def show
    render json: { ticket: serializador.ticket(conversa) }
  end

  # GET users/:id/tickets/requested.json — os tickets do usuário final.
  def requested
    contato = conta.contacts.find(Staydesk::Zendesk::Serializer.contato_de(params[:id]))
    conversas = contato.conversations.where(account_id: conta.id).order(created_at: :desc).limit(100)
    tickets = conversas.map { |c| serializador.ticket(c) }
    render json: { tickets: tickets, next_page: nil, count: tickets.size }
  end

  def comments
    mensagens = conversa.messages.where(message_type: %w[incoming outgoing]).order(:created_at)
    render json: { comments: mensagens.map { |m| serializador.comentario(m) }, next_page: nil, count: mensagens.size }
  end

  # PUT tickets/:id.json { ticket: { status, priority, assignee_id, group_id, tags, custom_fields, comment: { body, public } } }
  def update
    dados = params.require(:ticket).permit(
      :status, :priority, :assignee_id, :group_id, :subject,
      tags: [], custom_fields: [:id, :value], comment: [:body, :public]
    )
    Staydesk::Zendesk::TicketUpdater.new(conta, conversa).perform(dados.to_h)
    render json: { ticket: serializador.ticket(conversa.reload) }
  end

  def set_tags
    conversa.update_labels(Array(params[:tags]))
    render json: { tags: conversa.reload.cached_label_list_array }
  end

  def add_tags
    conversa.update_labels(conversa.cached_label_list_array | Array(params[:tags]))
    render json: { tags: conversa.reload.cached_label_list_array }
  end

  private

  def conversa
    @conversa ||= conta.conversations.find_by!(display_id: params[:id])
  end

  def pagina(por_pagina)
    escopo = a_partir_do_cursor(conta.conversations.includes(:inbox, :contact, :assignee, :team).order(:updated_at, :id))
    conversas = escopo.limit(por_pagina + 1).to_a
    [conversas.first(por_pagina), conversas.size <= por_pagina]
  end

  # O que `include` pede: usuários, grupos e metric sets, como o Zendesk devolve.
  def inclusoes(conversas, tickets)
    pedidos = params[:include].to_s.split(',')
    extras = {}
    extras[:users] = usuarios_de(conversas) if pedidos.include?('users')
    extras[:groups] = conta.teams.map { |time| serializador.grupo(time) } if pedidos.include?('groups')
    extras[:ticket_metric_sets] = tickets.pluck(:metric_set) if pedidos.include?('metric_sets')
    extras
  end

  # O cursor é "updated_at|id" da última conversa da página; sem cursor, vale start_time.
  def a_partir_do_cursor(escopo)
    if params[:cursor].present?
      carimbo, id = Base64.urlsafe_decode64(params[:cursor]).split('|')
      momento = Time.zone.at(carimbo.to_f)
      escopo.where('conversations.updated_at > ? OR (conversations.updated_at = ? AND conversations.id > ?)', momento, momento, id.to_i)
    else
      escopo.where(updated_at: unix(params[:start_time], Time.zone.at(0))..)
    end
  end

  def cursor_de(conversa)
    Base64.urlsafe_encode64("#{conversa.updated_at.to_f}|#{conversa.id}")
  end

  # Os agentes da conta e os contatos que aparecem nesta página, como usuários.
  def usuarios_de(conversas)
    agentes = conta.users.includes(:account_users).map { |user| serializador.usuario(user) }
    contatos = Contact.where(id: conversas.filter_map(&:contact_id).uniq).map { |contato| serializador.usuario_final(contato) }
    agentes + contatos
  end
end

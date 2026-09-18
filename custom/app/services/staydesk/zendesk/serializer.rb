# Traduz o que o StayDesk tem para o vocabulário do Zendesk que o dashboard
# entende: conversa vira ticket, contato vira usuário final, time vira grupo,
# evento de tempo vira metric set, avaliação vira satisfaction rating.
class Staydesk::Zendesk::Serializer
  # Contatos e usuários são tabelas diferentes aqui e uma só no Zendesk; o
  # deslocamento evita que um contato e um agente tenham o mesmo id lá.
  CONTATO_BASE = 1_000_000_000
  CANAIS = {
    'Channel::Email' => 'email', 'Channel::WebWidget' => 'chat', 'Channel::Whatsapp' => 'whatsapp',
    'Channel::Api' => 'api', 'Channel::Sms' => 'sms', 'Channel::TwilioSms' => 'sms',
    'Channel::FacebookPage' => 'facebook', 'Channel::Instagram' => 'instagram',
    'Channel::Telegram' => 'telegram', 'Channel::Line' => 'line', 'Channel::Voice' => 'voice'
  }.freeze
  PRIORIDADES = { 'low' => 'low', 'medium' => 'normal', 'high' => 'high', 'urgent' => 'urgent' }.freeze
  STATUS_DO_ZENDESK = { 'new' => 'open', 'open' => 'open', 'pending' => 'pending', 'hold' => 'snoozed',
                        'solved' => 'resolved', 'closed' => 'resolved' }.freeze

  def initialize(account)
    @account = account
  end

  def self.id_do_contato(contact_id)
    CONTATO_BASE + contact_id
  end

  def self.contato_de(id)
    id.to_i - CONTATO_BASE
  end

  def ticket(conversa)
    identidade(conversa).merge(quem(conversa)).merge(
      tags: conversa.cached_label_list_array, custom_fields: campos(conversa),
      satisfaction_rating: satisfacao(conversa), metric_set: metric_set(conversa)
    )
  end

  def usuario(user)
    {
      id: user.id, name: user.name, email: user.email,
      role: conta_do(user)&.administrator? ? 'admin' : 'agent',
      active: true, last_login_at: nil, created_at: user.created_at.utc.iso8601, updated_at: user.updated_at.utc.iso8601
    }
  end

  def usuario_final(contato)
    {
      id: self.class.id_do_contato(contato.id), name: contato.name, email: contato.email,
      phone: contato.phone_number, role: 'end-user', active: true, last_login_at: nil,
      created_at: contato.created_at.utc.iso8601, updated_at: contato.updated_at.utc.iso8601
    }
  end

  def grupo(time)
    { id: time.id, name: time.name, description: time.description, default: false, deleted: false,
      created_at: time.created_at.utc.iso8601, updated_at: time.updated_at.utc.iso8601 }
  end

  def campo_do_ticket(definicao)
    {
      id: definicao.id, type: tipo_do_campo(definicao), title: definicao.attribute_display_name,
      raw_title: definicao.attribute_display_name, key: definicao.attribute_key, description: definicao.attribute_description,
      active: true, required: false, removable: true,
      custom_field_options: Array(definicao.attribute_values).map { |valor| { id: valor.hash.abs, name: valor, value: valor } }
    }
  end

  def avaliacao(resposta)
    conversa = resposta.conversation
    {
      id: resposta.id, assignee_id: resposta.assigned_agent_id, group_id: conversa&.team_id,
      requester_id: self.class.id_do_contato(resposta.contact_id), ticket_id: conversa&.display_id,
      score: nota(resposta), comment: resposta.feedback_message,
      created_at: resposta.created_at.utc.iso8601, updated_at: resposta.updated_at.utc.iso8601
    }
  end

  def comentario(mensagem)
    {
      id: mensagem.id, type: 'Comment', author_id: autor(mensagem),
      body: mensagem.content.to_s, html_body: mensagem.content.to_s, plain_body: mensagem.content.to_s,
      public: !mensagem.private, created_at: mensagem.created_at.utc.iso8601,
      attachments: mensagem.attachments.map { |anexo| { id: anexo.id, file_name: anexo.file&.filename.to_s, content_url: anexo.file_url } }
    }
  end

  # Tempos no formato dos metric sets: minutos, no calendário e no horário comercial.
  def metric_set(conversa)
    eventos = ReportingEvent.where(conversation_id: conversa.id).order(:created_at).group_by(&:name)
    resolvida = eventos['conversation_resolved']&.last
    { ticket_id: conversa.display_id }
      .merge(tempos(eventos['first_response']&.first, eventos['conversation_resolved']&.first, resolvida))
      .merge(atividade(conversa, resolvida))
  end

  private

  def identidade(conversa)
    {
      id: conversa.display_id, url: nil, external_id: nil,
      subject: assunto(conversa), description: primeira_mensagem(conversa),
      status: status(conversa), priority: PRIORIDADES[conversa.priority.to_s], type: conversa.custom_attributes['tipo'],
      via: { channel: CANAIS.fetch(conversa.inbox&.channel_type, 'api'), source: { from: {}, to: {}, rel: nil } },
      created_at: conversa.created_at.utc.iso8601, updated_at: conversa.updated_at.utc.iso8601
    }
  end

  def quem(conversa)
    solicitante = conversa.contact_id && self.class.id_do_contato(conversa.contact_id)
    { requester_id: solicitante, submitter_id: solicitante, assignee_id: conversa.assignee_id, group_id: conversa.team_id,
      organization_id: nil, brand_id: nil }
  end

  def conta_do(user)
    user.account_users.find { |vinculo| vinculo.account_id == @account.id }
  end

  def assunto(conversa)
    conversa.custom_attributes['assunto'].presence || conversa.additional_attributes['assunto'].presence ||
      primeira_mensagem(conversa)&.truncate(80)
  end

  def primeira_mensagem(conversa)
    conversa.messages.incoming.order(:created_at).first&.content
  end

  # Aberta e sem resposta é "new"; resolvida com o status "Fechado" da operação é "closed".
  def status(conversa)
    case conversa.status
    when 'open' then conversa.first_reply_created_at ? 'open' : 'new'
    when 'pending' then 'pending'
    when 'snoozed' then 'hold'
    when 'resolved' then conversa.custom_attributes['staydesk_status'].to_s.match?(/fechad/i) ? 'closed' : 'solved'
    else conversa.status
    end
  end

  def campos(conversa)
    definicoes = @account.custom_attribute_definitions.where(attribute_model: 'conversation_attribute')
    definicoes.map { |definicao| { id: definicao.id, value: conversa.custom_attributes[definicao.attribute_key] } }
  end

  def satisfacao(conversa)
    resposta = CsatSurveyResponse.find_by(conversation_id: conversa.id)
    return { score: 'unoffered' } if resposta.blank?

    { id: resposta.id, score: nota(resposta), comment: resposta.feedback_message, reason_id: nil, reason_code: nil }
  end

  def nota(resposta)
    base = resposta.rating >= 4 ? 'good' : 'bad'
    resposta.feedback_message.present? ? "#{base}_with_comment" : base
  end

  def tipo_do_campo(definicao)
    { 'text' => 'text', 'number' => 'integer', 'date' => 'date', 'list' => 'tagger', 'checkbox' => 'checkbox', 'link' => 'text' }
      .fetch(definicao.attribute_display_type.to_s, 'text')
  end

  def tempos(primeira, primeira_resolucao, resolvida)
    vazio = { calendar: nil, business: nil }
    { reply_time_in_minutes: minutos(primeira), first_resolution_time_in_minutes: minutos(primeira_resolucao),
      full_resolution_time_in_minutes: minutos(resolvida), agent_wait_time_in_minutes: vazio,
      requester_wait_time_in_minutes: vazio, on_hold_time_in_minutes: vazio }
  end

  def atividade(conversa, resolvida)
    { reopens: reaberturas(conversa), replies: conversa.messages.outgoing.where(private: false).count,
      assignee_updated_at: ultimo_evento(conversa, 'assignee_changed'), solved_at: resolvida&.created_at&.utc&.iso8601,
      latest_comment_added_at: conversa.messages.maximum(:created_at)&.utc&.iso8601,
      created_at: conversa.created_at.utc.iso8601, updated_at: conversa.updated_at.utc.iso8601 }
  end

  def minutos(evento)
    return { calendar: nil, business: nil } if evento.blank?

    { calendar: (evento.value.to_f / 60).round, business: evento.value_in_business_hours ? (evento.value_in_business_hours.to_f / 60).round : nil }
  end

  def reaberturas(conversa)
    Staydesk::ConversationEvent.where(conversation_id: conversa.id, kind: 'status_changed', from_value: 'resolved', to_value: 'open').count
  end

  def ultimo_evento(conversa, kind)
    Staydesk::ConversationEvent.where(conversation_id: conversa.id, kind: kind).maximum(:created_at)&.utc&.iso8601
  end

  def autor(mensagem)
    return self.class.id_do_contato(mensagem.sender_id) if mensagem.sender_type == 'Contact'

    mensagem.sender_id
  end
end

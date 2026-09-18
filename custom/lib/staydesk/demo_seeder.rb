# Dados fictícios para ver as telas do StayDesk com volume: agentes, times, caixas,
# catálogos (status do ticket, status do agente, SLA), visualizações, contatos e
# conversas espalhadas por fila, status e responsável.
#
# Uso: bundle exec rails staydesk:demo [ACCOUNT_ID=1] [RESET=1]
class Staydesk::DemoSeeder # rubocop:disable Metrics/ClassLength
  SUFIXO = 'staydesk.test'.freeze
  SENHA = 'Staydesk#2026'.freeze

  TIMES = ['Suporte N1', 'Suporte N2', 'Sucesso do Cliente'].freeze

  AGENTES = [
    { nome: 'Ana Ribeiro', email: "ana@#{SUFIXO}", time: 'Suporte N1', status: 'Só chat' },
    { nome: 'Bruno Tavares', email: "bruno@#{SUFIXO}", time: 'Suporte N1', status: 'Disponível' },
    { nome: 'Carla Duarte', email: "carla@#{SUFIXO}", time: 'Suporte N2', status: 'Só tickets' },
    { nome: 'Diego Farias', email: "diego@#{SUFIXO}", time: 'Sucesso do Cliente', status: 'Reunião' }
  ].freeze

  ETIQUETAS = [
    { title: 'migracao', color: '#545DFF' }, { title: 'ssl', color: '#1a9f63' },
    { title: 'backup', color: '#f59e0b' }, { title: 'financeiro', color: '#0ea5e9' },
    { title: 'dns', color: '#a855f7' }, { title: 'vps', color: '#64748b' },
    { title: 'urgente', color: '#e11d48' }
  ].freeze

  CORES_DE_STATUS = %w[#545DFF #0ea5e9 #f59e0b #a855f7 #1a9f63 #64748b].freeze
  CORES_DE_VIEW = %w[#545DFF #0ea5e9 #f59e0b].freeze

  CONTATOS = [
    ['Marina Alencar', 'Pousada Vista Verde'], ['Rogério Pimentel', 'Clínica Bem Estar'],
    ['Tatiane Moraes', 'Studio Moraes Fotografia'], ['Leandro Bastos', 'Bastos Contabilidade'],
    ['Priscila Nogueira', 'Escola Criativa'], ['Fernando Rangel', 'Rangel Advocacia'],
    ['Juliana Peixoto', 'Ateliê Peixoto'], ['Marcelo Quintana', 'Quintana Imóveis'],
    ['Renata Vilela', 'Vilela Turismo'], ['Otávio Serrano', 'Serrano Distribuidora'],
    ['Camila Furtado', 'Furtado Odontologia'], ['Gustavo Andrade', 'Andrade Engenharia'],
    ['Bianca Lousada', 'Lousada Cosméticos'], ['Henrique Vasques', 'Vasques Autopeças'],
    ['Aline Portela', 'Portela Eventos'], ['Rodrigo Caldeira', 'Caldeira Transportes'],
    ['Sabrina Toledo', 'Toledo Pet Shop'], ['Vitor Hugo Maia', 'Maia Consultoria'],
    ['Letícia Barroso', 'Barroso Design'], ['Eduardo Prates', 'Prates Materiais']
  ].freeze

  ASSUNTOS_CHAT = [
    'Site fora do ar depois da atualização', 'Certificado SSL expirou hoje',
    'Não consigo acessar o painel', 'E-mail caindo em spam',
    'Lentidão no site desde ontem', 'Preciso liberar um IP no firewall',
    'Erro 500 na loja virtual', 'Como aponto meu domínio novo?',
    'Backup automático parou de rodar', 'Quero aumentar a memória do plano'
  ].freeze

  ASSUNTOS_TICKET = [
    'Solicitação de migração de servidor', 'Segunda via da fatura de setembro',
    'Upgrade de plano para VPS dedicada', 'Relatório de uso de banda do mês',
    'Cancelamento de serviço adicional', 'Liberação de porta SMTP',
    'Restauração de backup de 3 dias atrás', 'Renovação antecipada do domínio',
    'Configuração de DNS para novo subdomínio', 'Ajuste de limite de contas de e-mail'
  ].freeze

  FALAS_CLIENTE = [
    'Bom dia! Estou com um problema desde ontem à noite e preciso de ajuda.',
    'Alguém pode olhar isso com urgência? Está afetando meus clientes.',
    'Segue o print do erro que aparece na tela.',
    'Consigo aguardar até amanhã, mas preciso de uma previsão.',
    'Obrigado pelo retorno rápido, vou testar aqui.',
    'Ainda não resolveu, o erro voltou agora há pouco.'
  ].freeze

  FALAS_AGENTE = [
    'Olá! Já estou verificando por aqui, um instante.',
    'Consegui identificar a causa, vou aplicar o ajuste agora.',
    'Pode testar novamente e me confirmar, por favor?',
    'Abri um chamado com a equipe de infraestrutura e acompanho de perto.',
    'Ajuste aplicado. Qualquer coisa é só chamar por aqui.',
    'Enviei o passo a passo no seu e-mail também.'
  ].freeze

  def initialize(account:, reset: false)
    @account = account
    @reset = reset
    @rng = Random.new(2026)
  end

  def perform!
    limpar if @reset
    preparar_conta
    @times = semear_times
    @caixas = semear_caixas
    @agentes = semear_agentes
    semear_etiquetas
    semear_atributos
    semear_catalogo_de_tickets
    @status_de_agente = semear_status_de_agente
    semear_calendario_e_sla
    semear_visualizacoes
    semear_areas_de_trabalho
    @contatos = semear_contatos
    semear_conversas
    semear_historico
    semear_csat
    distribuir_status_dos_agentes
    resumo
  end

  # Só o histórico do cliente, sem recriar a operação do dia.
  def historico!
    @times = semear_times
    @caixas = semear_caixas
    @agentes = semear_agentes
    @contatos = semear_contatos
    semear_historico
    resumo
  end

  private

  def limpar
    @account.conversations.destroy_all
    @account.contacts.where('email LIKE ?', "%@#{SUFIXO}").destroy_all
  end

  def preparar_conta
    @account.update!(name: 'StayCloud', locale: 'pt_BR')
  end

  # O Chatwoot guarda o nome do time em minúsculas, então a busca é sem caixa.
  def semear_times
    TIMES.index_with do |nome|
      @account.teams.find_by('lower(name) = ?', nome.downcase) || @account.teams.create!(name: nome)
    end
  end

  def semear_caixas
    site = @account.inboxes.find_by(channel_type: 'Channel::WebWidget') || criar_widget
    site.update!(name: 'Chat do site')
    site.channel.update!(website_url: "https://#{SUFIXO}")
    {
      chat_site: site,
      whatsapp: caixa_de_api('WhatsApp Suporte'),
      email_suporte: caixa_de_email('E-mail Suporte', "suporte@#{SUFIXO}"),
      email_financeiro: caixa_de_email('E-mail Financeiro', "financeiro@#{SUFIXO}")
    }
  end

  def criar_widget
    canal = Channel::WebWidget.create!(account: @account, website_url: "https://#{SUFIXO}")
    Inbox.create!(account: @account, channel: canal, name: 'Chat do site')
  end

  def caixa_de_api(nome)
    existente = @account.inboxes.find_by(name: nome)
    return existente if existente

    canal = Channel::Api.create!(account: @account, webhook_url: '')
    Inbox.create!(account: @account, channel: canal, name: nome)
  end

  def caixa_de_email(nome, endereco)
    existente = @account.inboxes.find_by(name: nome)
    return existente if existente

    canal = Channel::Email.create!(account: @account, email: endereco, forward_to_email: endereco)
    Inbox.create!(account: @account, channel: canal, name: nome)
  end

  def semear_agentes
    AGENTES.map do |dados|
      usuario = User.from_email(dados[:email]) || User.create!(
        name: dados[:nome], email: dados[:email], password: SENHA, confirmed_at: Time.current
      )
      AccountUser.find_or_create_by!(account: @account, user: usuario) { |vinculo| vinculo.role = :agent }
      TeamMember.find_or_create_by!(team: @times.fetch(dados[:time]), user: usuario)
      @caixas.each_value { |caixa| InboxMember.find_or_create_by!(inbox: caixa, user: usuario) }
      dados.merge(usuario: usuario)
    end
  end

  def semear_etiquetas
    ETIQUETAS.each { |etiqueta| @account.labels.find_or_create_by!(title: etiqueta[:title]) { |l| l.color = etiqueta[:color] } }
  end

  def semear_atributos
    definicao = @account.custom_attribute_definitions.find_or_initialize_by(
      attribute_key: 'assunto', attribute_model: 'conversation_attribute'
    )
    definicao.update!(attribute_display_name: 'Assunto', attribute_display_type: 'text')
  end

  def semear_catalogo_de_tickets
    [
      ['Novo', 'open', true, 'Chegou e ninguém pegou ainda'],
      ['Em atendimento', 'open', false, 'Alguém está tocando agora'],
      ['Aguardando cliente', 'snoozed', true, 'Volta sozinho quando o cliente responder'],
      ['Em espera', 'pending', true, 'Parado por dependência interna ou de terceiro'],
      ['Resolvido', 'resolved', true, 'Entregue, aguardando confirmação'],
      ['Fechado', 'resolved', false, 'Encerrado de vez']
    ].each_with_index do |(nome, base, padrao, descricao), indice|
      status = Staydesk::TicketStatus.find_or_initialize_by(account: @account, name: nome)
      status.update!(base_status: base, default_for_base: padrao, description: descricao,
                     position: indice, color: CORES_DE_STATUS[indice])
    end
  end

  def semear_status_de_agente
    chats = [@caixas[:chat_site].id, @caixas[:whatsapp].id]
    tickets = [@caixas[:email_suporte].id, @caixas[:email_financeiro].id]
    regra = Staydesk::CapacityRule.find_or_initialize_by(account: @account, name: 'Padrão')
    regra.update!(limits: { 'chat' => 5, 'ticket' => 15 }, is_default: true)
    [
      ['Disponível', 'online', [], %w[chat ticket], '#1a9f63'],
      ['Só chat', 'online', chats, %w[chat], '#545DFF'],
      ['Só tickets', 'online', tickets, %w[ticket], '#0ea5e9'],
      ['Reunião', 'busy', [], [], '#f59e0b'],
      ['Almoço', 'busy', [], [], '#64748b']
    ].each_with_index.to_h do |(nome, disponibilidade, caixas, canais, cor), indice|
      status = Staydesk::AgentStatus.find_or_initialize_by(account: @account, name: nome)
      status.update!(availability: disponibilidade, inbox_ids: caixas, work_channels: canais, color: cor, position: indice)
      [nome, status]
    end
  end

  def semear_calendario_e_sla
    calendario = Staydesk::Calendar.find_or_initialize_by(account: @account, name: 'Comercial')
    calendario.update!(
      timezone: 'America/Sao_Paulo',
      weekly_hours: (1..5).map { |dia| { 'day' => dia, 'open' => '09:00', 'close' => '18:00' } },
      holidays: [{ 'date' => '2026-10-12', 'name' => 'Nossa Senhora Aparecida' },
                 { 'date' => '2026-11-15', 'name' => 'Proclamação da República' },
                 { 'date' => '2026-12-25', 'name' => 'Natal' }]
    )

    padrao = Staydesk::SlaPolicy.find_or_initialize_by(account: @account, name: 'Padrão')
    padrao.update!(description: 'Vale para tudo que não se encaixa em outra política', calendar: calendario, position: 1,
                   conditions: [{ 'attribute_key' => 'status', 'filter_operator' => 'not_equal_to', 'values' => ['resolved'] }],
                   targets: { 'default' => { 'first_response' => 30, 'next_response' => 60, 'resolution' => 480 },
                              'urgent' => { 'first_response' => 10, 'next_response' => 20, 'resolution' => 240 },
                              'high' => { 'first_response' => 20, 'next_response' => 40, 'resolution' => 360 } })

    urgente = Staydesk::SlaPolicy.find_or_initialize_by(account: @account, name: 'Fora do ar')
    urgente.update!(description: 'Conversas marcadas como urgentes no chat', calendar: nil, position: 0,
                    conditions: [{ 'attribute_key' => 'priority', 'filter_operator' => 'equal_to', 'values' => ['urgent'] }],
                    targets: { 'default' => { 'first_response' => 5, 'next_response' => 15, 'resolution' => 120 } })
  end

  def semear_visualizacoes
    [
      ['Fila do chat', 'Conversas abertas dos canais de chat', %w[sla status subject contact waiting_since assignee],
       [{ 'attribute_key' => 'status', 'filter_operator' => 'equal_to', 'values' => ['open'] }]],
      ['Tickets sem responsável', 'E-mails que ninguém pegou', %w[status subject contact inbox created_at priority],
       [{ 'attribute_key' => 'assignee_id', 'filter_operator' => 'is_not_present', 'values' => [] }]],
      ['Em espera', 'Parados por dependência', %w[status subject contact assignee waiting_since team],
       [{ 'attribute_key' => 'status', 'filter_operator' => 'equal_to', 'values' => ['pending'] }]]
    ].each_with_index do |(nome, descricao, colunas, consulta), indice|
      view = Staydesk::TeamView.find_or_initialize_by(account: @account, name: nome)
      view.update!(description: descricao, columns: colunas, query: { 'payload' => consulta },
                   position: indice, color: CORES_DE_VIEW[indice], sort_by: 'last_activity_at_asc')
    end
  end

  # Padrão da conta em tabela (o jeito Zendesk) e um recorte mais enxuto para o N1,
  # para dar para ver a diferença de área de trabalho por time.
  def semear_areas_de_trabalho
    padrao = Staydesk::TeamWorkspace.find_or_initialize_by(account: @account, team_id: nil)
    padrao.update!(config: {
                     'list' => { 'layout' => 'table', 'page_size' => 25,
                                 'columns' => %w[sla status subject contact inbox waiting_since assignee],
                                 'sort_by' => 'last_activity_at_asc',
                                 # Quem atende não vê fila: só o que é dele. Quem coordena vê tudo.
                                 'tabs' => %w[me] },
                     'roles' => { 'administrator' => { 'list' => { 'tabs' => %w[me unassigned all] } } }
                   })

    # Um recorte por time, para dar para ver a diferença na tela de área de trabalho.
    n1 = Staydesk::TeamWorkspace.find_or_initialize_by(account: @account, team_id: @times.fetch('Suporte N1').id)
    n1.update!(config: { 'list' => { 'columns' => %w[status subject contact waiting_since] } })
  end

  def semear_contatos
    CONTATOS.each_with_index.map do |(nome, empresa), indice|
      email = "#{nome.parameterize.tr('-', '.')}@#{SUFIXO}"
      contato = @account.contacts.from_email(email) || @account.contacts.create!(
        name: nome, email: email, phone_number: format('+5511%09d', 900_000_000 + indice),
        additional_attributes: { 'company_name' => empresa }
      )
      contato
    end
  end

  def semear_conversas
    45.times { |indice| criar_conversa(indice) }
  end

  def criar_conversa(indice)
    contato = @contatos[(indice * 3) % @contatos.size]
    status, responsavel = situacao(indice)
    criada_em = nascida_em(indice)

    conversa = Conversation.create!(atributos_da_conversa(caixa_da_vez(indice), contato, responsavel, indice, criada_em))
    conversa.add_labels([ETIQUETAS[indice % ETIQUETAS.size][:title]])
    # As mensagens vêm antes do status: mensagem do cliente reabre conversa adiada
    # ou resolvida, então o status final é aplicado depois, pelo serviço da SPEC-10.
    criar_mensagens(conversa, contato, responsavel, criada_em)
    aplicar_status_de_ticket(conversa, status, responsavel)
  end

  # Histórico do cliente: casos antigos e já encerrados, para a aba "conversas
  # anteriores" ter o que mostrar e a navegação entre tickets ser testável.
  def semear_historico
    @contatos.each_with_index do |contato, indice|
      next if historico?(contato)

      (3 + @rng.rand(4)).times { |passo| criar_conversa_antiga(contato, indice, passo) }
    end
  end

  # Pesquisa de satisfação respondida em parte das conversas encerradas, para o
  # CSAT da Central não nascer vazio. A distribuição imita a real: quase tudo bom.
  NOTAS = [5, 5, 5, 5, 4, 4, 4, 3, 2, 1].freeze

  def semear_csat
    encerradas = @account.conversations.resolved.where.not(assignee_id: nil).order(:id)
    encerradas.each_with_index do |conversa, indice|
      next if indice.odd?
      next if CsatSurveyResponse.exists?(conversation_id: conversa.id)

      mensagem = conversa.messages.where(message_type: :outgoing).last
      next if mensagem.blank?

      CsatSurveyResponse.create!(
        account_id: @account.id, conversation_id: conversa.id, message_id: mensagem.id,
        contact_id: conversa.contact_id, assigned_agent_id: conversa.assignee_id,
        rating: NOTAS[indice % NOTAS.size], created_at: conversa.updated_at
      )
    end
  end

  def historico?(contato)
    conversas_de_historico.exists?(contact_id: contato.id)
  end

  def criar_conversa_antiga(contato, indice, passo)
    posicao = (indice * 5) + passo
    responsavel = @agentes[posicao % @agentes.size][:usuario]
    criada_em = (15 + ((posicao * 11) % 165)).days.ago - (passo * 7).hours

    conversa = Conversation.create!(atributos_do_historico(contato, responsavel, posicao, criada_em))
    conversa.add_labels([ETIQUETAS[posicao % ETIQUETAS.size][:title]])
    criar_mensagens(conversa, contato, responsavel, criada_em)
    encerrar(conversa, criada_em)
  end

  def atributos_do_historico(contato, responsavel, posicao, criada_em)
    atributos = atributos_da_conversa(caixa_da_vez(posicao), contato, responsavel, posicao, criada_em)
    atributos.merge(custom_attributes: atributos[:custom_attributes].merge('staydesk_demo' => 'historico'))
  end

  # Encerra no passado: o histórico não pode ficar pendurado nas filas de hoje.
  def encerrar(conversa, criada_em)
    aplicar_status_de_ticket(conversa, 'resolved', conversa.assignee)
    fechada_em = criada_em + (2 + @rng.rand(40)).hours
    # rubocop:disable Rails/SkipsModelValidations
    conversa.update_columns(updated_at: fechada_em, last_activity_at: fechada_em)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def nascida_em(indice)
    2.hours.ago - ((indice % 10) * 27).hours - (indice * 13).minutes
  end

  def atributos_da_conversa(caixa, contato, responsavel, indice, criada_em)
    assuntos = Staydesk::AgentLoadService.queue_for(caixa) == 'chat' ? ASSUNTOS_CHAT : ASSUNTOS_TICKET
    {
      account: @account, inbox: caixa, contact: contato,
      contact_inbox: vinculo(contato, caixa), assignee: responsavel,
      team: responsavel ? time_do_agente(responsavel) : nil,
      priority: prioridade(indice), created_at: criada_em,
      custom_attributes: { 'assunto' => assuntos[(indice * 7) % assuntos.size] }
    }
  end

  def caixa_da_vez(indice)
    [@caixas[:chat_site], @caixas[:whatsapp], @caixas[:email_suporte],
     @caixas[:chat_site], @caixas[:email_financeiro]][indice % 5]
  end

  # Mistura de situações para as telas terem fila, trabalho em curso e histórico.
  def situacao(indice)
    case indice % 9
    when 0, 1 then ['open', nil]
    when 2, 3, 4 then ['open', @agentes[indice % @agentes.size][:usuario]]
    when 5 then ['pending', @agentes[indice % @agentes.size][:usuario]]
    when 6 then ['snoozed', @agentes[indice % @agentes.size][:usuario]]
    else ['resolved', @agentes[indice % @agentes.size][:usuario]]
    end
  end

  def prioridade(indice)
    case indice % 7
    when 0 then 'urgent'
    when 1 then 'high'
    when 2 then 'medium'
    when 3 then 'low'
    end
  end

  def time_do_agente(usuario)
    @times.values.find { |time| time.members.exists?(id: usuario.id) }
  end

  def vinculo(contato, caixa)
    ContactInbox.find_by(contact: contato, inbox: caixa) ||
      ContactInbox.create!(contact: contato, inbox: caixa, source_id: SecureRandom.uuid)
  end

  def criar_mensagens(conversa, contato, responsavel, criada_em)
    quantidade = 2 + (@rng.rand(4))
    quantidade.times do |passo|
      do_cliente = passo.even?
      conversa.messages.create!(
        account: @account, inbox: conversa.inbox,
        message_type: do_cliente ? :incoming : :outgoing,
        content: do_cliente ? FALAS_CLIENTE[passo % FALAS_CLIENTE.size] : FALAS_AGENTE[passo % FALAS_AGENTE.size],
        sender: do_cliente ? contato : (responsavel || @agentes.first[:usuario]),
        created_at: [criada_em + (passo * 18).minutes, 1.minute.ago].min
      )
    end
  end

  def aplicar_status_de_ticket(conversa, status, responsavel)
    # O catálogo da conta manda: se o nome preferido não existe, vale o padrão da base.
    ticket_status = Staydesk::TicketStatus.find_by(account: @account, name: nome_do_status(conversa, status, responsavel)) ||
                    Staydesk::TicketStatus.default_for(@account, status)
    return if ticket_status.blank?

    Staydesk::TicketStatusService.new(conversa).apply(ticket_status)
  end

  def nome_do_status(conversa, status, responsavel)
    case status
    when 'open' then responsavel ? 'Em atendimento' : 'Novo'
    when 'pending' then 'Em espera'
    when 'snoozed' then 'Aguardando cliente'
    else conversa.id.even? ? 'Resolvido' : 'Fechado'
    end
  end

  def distribuir_status_dos_agentes
    @agentes.each do |dados|
      status = @status_de_agente[dados[:status]]
      next if status.blank?

      vinculo = @account.account_users.find_by(user: dados[:usuario])
      Staydesk::AgentStatusService.new(vinculo).change_to(status)
    end
  end

  def conversas_de_historico
    @account.conversations.where("custom_attributes->>'staydesk_demo' = 'historico'")
  end

  def contagem_do_catalogo
    {
      status_de_ticket: Staydesk::TicketStatus.where(account: @account).count,
      status_de_agente: Staydesk::AgentStatus.where(account: @account).count,
      visualizacoes: Staydesk::TeamView.where(account: @account).count,
      politicas_de_sla: Staydesk::SlaPolicy.where(account: @account).count,
      areas_de_trabalho: Staydesk::TeamWorkspace.where(account: @account).count
    }
  end

  def resumo
    {
      conta: @account.name,
      agentes: @account.users.count,
      caixas: @account.inboxes.pluck(:name),
      contatos: @account.contacts.count,
      conversas: @account.conversations.group(:status).count,
      historico: conversas_de_historico.count,
      csat: CsatSurveyResponse.where(account_id: @account.id).count,
      catalogo: contagem_do_catalogo,
      slas_aplicados: Staydesk::AppliedSla.where(account: @account).group(:status).count,
      status_dos_tickets: @account.conversations.group("custom_attributes->>'staydesk_status'").count
    }
  end
end

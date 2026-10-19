# As macros da operação dentro do importador, como as do Zendesk: resposta pronta,
# nota interna, grupo, status do ticket, etiqueta e campos, num clique. Entram
# como macros da conta (visíveis a todos) e são reconhecidas pelo nome, então
# importar de novo atualiza em vez de duplicar.
module Staydesk::ConfigImport::Macros
  private

  def importar_macros
    secao('macros').map do |dados|
      macro = @account.macros.find_or_initialize_by(name: dados.fetch('nome'))
      macro.update!(visibility: :global, actions: acoes_da_macro(dados))
      macro.name
    end
  end

  def acoes_da_macro(dados)
    acoes_pelo_nome(dados.fetch('acoes'))
  end

  # Vale para macros e gatilhos. Grupo e status do ticket vêm pelo nome e o
  # agente pelo e-mail, que é o que a operação escreve; o produto guarda o id.
  # O que não existe na conta é ignorado, sem derrubar a importação.
  RESOLVIDAS_PELO_NOME = %w[assign_team assign_agent staydesk_set_ticket_status].freeze

  def acoes_pelo_nome(acoes)
    acoes.filter_map do |acao|
      parametros = Array(acao['valores'] || acao['valor'])
      parametros = parametros.filter_map { |valor| id_pelo_nome(acao.fetch('tipo'), valor) } if RESOLVIDAS_PELO_NOME.include?(acao['tipo'])
      next if parametros.empty? && RESOLVIDAS_PELO_NOME.include?(acao['tipo'])

      { 'action_name' => acao['tipo'], 'action_params' => parametros }
    end
  end

  def id_pelo_nome(tipo, valor)
    return valor if valor.is_a?(Integer)

    { 'assign_team' => -> { time_existente(valor) }, 'assign_agent' => -> { @account.users.from_email(valor.to_s) },
      'staydesk_set_ticket_status' => -> { status_do_ticket(valor) } }.fetch(tipo).call&.id
  end

  def time_existente(nome)
    @account.teams.find_by('lower(name) = ?', nome.to_s.downcase)
  end

  def status_do_ticket(nome)
    Staydesk::TicketStatus.find_by(account: @account, name: nome)
  end
end

# Aplica na conta uma configuração completa da operação, vinda de um YAML:
# times, etiquetas, atributos de conversa, status do ticket, status do agente,
# calendário, políticas de SLA, visualizações por time e área de trabalho.
# Idempotente: roda de novo e só atualiza o que mudou.
#
# Uso: rails staydesk:configurar ACCOUNT_ID=1 FILE=configuracao.yml
class Staydesk::ConfigImportService
  include Staydesk::ConfigImport::Catalogo

  def initialize(account:, config:)
    @account = account
    @config = config
  end

  def perform
    {
      times: importar_times,
      etiquetas: importar_etiquetas,
      atributos: importar_atributos,
      caixas: configurar_caixas,
      status_do_ticket: importar_status_do_ticket,
      filas_de_carga: importar_filas_de_carga,
      status_do_agente: importar_status_do_agente,
      calendario: importar_calendario&.name,
      politicas_de_sla: importar_politicas,
      filas: importar_filas,
      visualizacoes: importar_visualizacoes,
      area_de_trabalho: importar_area_de_trabalho
    }
  end

  private

  def secao(chave)
    @config[chave] || []
  end

  def importar_times
    secao('times').map { |nome| time!(nome).name }
  end

  def time!(nome)
    @account.teams.find_by('lower(name) = ?', nome.strip.downcase) || @account.teams.create!(name: nome.strip)
  end

  def importar_etiquetas
    secao('etiquetas').map do |dados|
      nome = dados.is_a?(Hash) ? dados.fetch('nome') : dados
      etiqueta = @account.labels.find_or_initialize_by(title: nome.to_s.strip.downcase)
      etiqueta.update!(color: (dados.is_a?(Hash) && dados['cor']) || etiqueta.color || '#545DFF')
      etiqueta.title
    end
  end

  def importar_atributos
    secao('atributos').map do |dados|
      definicao = @account.custom_attribute_definitions.find_or_initialize_by(
        attribute_key: dados.fetch('chave'), attribute_model: dados['modelo'] || 'conversation_attribute'
      )
      definicao.update!(
        attribute_display_name: dados.fetch('nome'),
        attribute_display_type: dados['tipo'] || 'text',
        attribute_values: dados['valores'] || []
      )
      definicao.attribute_key
    end
  end

  # Ajustes por caixa de entrada: pesquisa de satisfação ligada e a regra de
  # etiqueta que tira certos casos da pesquisa (o fora de horário, por exemplo).
  def configurar_caixas(_ = nil)
    secao('caixas').filter_map do |dados|
      caixa = @account.inboxes.find_by(name: dados.fetch('nome'))
      next if caixa.blank?

      caixa.update!(
        csat_survey_enabled: dados.fetch('pesquisa_de_satisfacao', caixa.csat_survey_enabled),
        csat_config: regra_de_csat(dados, caixa),
        enable_auto_assignment: dados.fetch('distribuicao_automatica', caixa.enable_auto_assignment)
      )
      caixa.name
    end
  end

  def regra_de_csat(dados, caixa)
    sem = dados['sem_pesquisa_com_etiquetas']
    return caixa.csat_config if sem.blank?

    (caixa.csat_config || {}).merge('survey_rules' => { 'operator' => 'does_not_contain', 'values' => sem })
  end

  def importar_politicas
    secao('politicas_de_sla').each_with_index.map do |dados, posicao|
      politica = Staydesk::SlaPolicy.find_or_initialize_by(account: @account, name: dados.fetch('nome'))
      politica.update!(
        description: dados['descricao'],
        calendar: dados['calendario'] ? Staydesk::Calendar.find_by(account: @account, name: dados['calendario']) : nil,
        conditions: condicoes(dados),
        targets: dados.fetch('alvos'),
        pause_statuses: dados['pausa_em'] || %w[pending snoozed],
        position: posicao, active: true
      )
      politica.name
    end
  end

  # Condições no formato do filtro avançado. Canal e caixa não entram aqui: são
  # campos próprios da fila, porque é assim que a operação pensa a entrada.
  def condicoes(dados)
    dados['condicoes'] || []
  end

  def caixas_por_nome(nomes)
    return [] if nomes.blank?

    @account.inboxes.where(name: nomes).pluck(:id)
  end

  def importar_filas
    secao('filas').each_with_index.map do |dados, posicao|
      fila = Staydesk::Queue.find_or_initialize_by(account: @account, name: dados.fetch('nome'))
      fila.update!(atributos_da_fila(dados).merge(position: posicao, active: true))
      fila.name
    end
  end

  def atributos_da_fila(dados)
    {
      description: dados['descricao'], team: time!(dados.fetch('time')),
      channel_types: Array(dados['canais']), inbox_ids: caixas_por_nome(dados['caixas']),
      conditions: condicoes(dados)
    }.merge(entrega_da_fila(dados))
  end

  # Como a fila entrega: quem ajuda, em que ordem e se exige aceite.
  def entrega_da_fila(dados)
    {
      fallback_team_ids: (dados['times_que_ajudam'] || dados['times_de_transbordo'] || []).map { |nome| time!(nome).id },
      fallback_mode: dados['ajuda'] || 'quando_faltar',
      priority_mode: dados['prioridade'] || 'chegada',
      fallback_after_minutes: dados['espera_minutos'],
      accept_required: dados.fetch('exige_aceite', false),
      accept_timeout_seconds: dados['segundos_para_aceitar'] || 30
    }
  end

  def importar_visualizacoes
    definicoes = secao('visualizacoes').map do |dados|
      {
        'name' => dados.fetch('nome'), 'description' => dados['descricao'], 'color' => dados['cor'],
        'sort_by' => dados['ordem'], 'columns' => dados['colunas'], 'teams' => dados['times'],
        'query' => { 'payload' => consulta_da_visualizacao(dados) }
      }
    end
    Staydesk::TeamViewImportService.new(account: @account, definitions: definicoes).perform.map(&:name)
  end

  # `caixas` na visualização vira uma linha de filtro por caixa de entrada, para o
  # YAML falar de nomes e não de ids, que mudam de ambiente para ambiente.
  def consulta_da_visualizacao(dados)
    linhas = dados.fetch('consulta').map(&:dup)
    caixas = caixas_por_nome(dados['caixas'])
    linhas = [{ 'attribute_key' => 'inbox_id', 'filter_operator' => 'equal_to', 'values' => caixas }] + linhas if caixas.any?
    linhas.each_with_index.map do |linha, indice|
      linha['query_operator'] = indice == linhas.size - 1 ? nil : (linha['query_operator'] || 'and')
      linha
    end
  end

  def importar_area_de_trabalho
    dados = @config['area_de_trabalho']
    return if dados.blank?

    padrao = Staydesk::TeamWorkspace.find_or_initialize_by(account: @account, team_id: nil)
    padrao.update!(config: dados.fetch('padrao'))
    (dados['times'] || {}).each do |nome, config|
      workspace = Staydesk::TeamWorkspace.find_or_initialize_by(account: @account, team_id: time!(nome).id)
      workspace.update!(config: config)
    end
    'aplicada'
  end
end

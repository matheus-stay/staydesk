# As visualizações da barra lateral dentro do importador.
# Separado para o importador não virar uma classe só.
module Staydesk::ConfigImport::Visualizacoes
  private

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
  #
  # `caixas_exceto` faz o contrário e é o que a fila de chat precisa: listar as
  # caixas que NÃO entram (as de ticket) em vez de listar as que entram. Assim a
  # visualização acompanha a fila de carga coringa — canal novo aparece sozinho,
  # em vez de nascer invisível até alguém lembrar de citá-lo aqui.
  def consulta_da_visualizacao(dados)
    linhas = dados.fetch('consulta').map(&:dup)
    linhas = [linha_de_caixas(dados), linha_de_grupos(dados)].compact + linhas
    linhas.each_with_index.map do |linha, indice|
      linha['query_operator'] = indice == linhas.size - 1 ? nil : (linha['query_operator'] || 'and')
      linha
    end
  end

  # Uma das duas, nunca as duas: citar caixas e exceções na mesma visualização é
  # contradição, e o silêncio de uma regra que não se aplica custa caro depois.
  def linha_de_caixas(dados)
    incluidas = caixas_por_nome(dados['caixas'])
    excluidas = caixas_por_nome(dados['caixas_exceto'])
    raise ArgumentError, "Visualização #{dados['nome']}: use `caixas` ou `caixas_exceto`, não as duas" if incluidas.any? && excluidas.any?

    return { 'attribute_key' => 'inbox_id', 'filter_operator' => 'equal_to', 'values' => incluidas } if incluidas.any?
    return { 'attribute_key' => 'inbox_id', 'filter_operator' => 'not_equal_to', 'values' => excluidas } if excluidas.any?

    nil
  end

  # `grupos` filtra a visualização pelo grupo dono do caso, também por nome, que
  # é o que a visão de engenharia precisa: o que foi escalado para o dev e está
  # parado lá. Sem isso ela só sabia dizer "não resolvido", e pegava tudo.
  def linha_de_grupos(dados)
    ids = times_por_nome(dados['grupos'])
    return nil if ids.blank?

    { 'attribute_key' => 'team_id', 'filter_operator' => 'equal_to', 'values' => ids }
  end

  def times_por_nome(nomes)
    return [] if nomes.blank?

    @account.teams.where('lower(name) IN (?)', Array(nomes).map(&:downcase)).pluck(:id)
  end
end

# Os gatilhos da operação dentro do importador, como a resposta automática de
# recebimento. Separado para o importador não virar uma classe só.
module Staydesk::ConfigImport::Automacoes
  private

  # Gatilhos, como no Zendesk: "quando entrar um ticket por e-mail, avise o
  # cliente que recebemos". O texto aceita as variáveis do produto, então
  # `{{conversation.display_id}}` vira o número do ticket na hora do envio.
  def importar_automacoes
    secao('automacoes').map { |dados| importar_automacao(dados) }
  end

  def importar_automacao(dados)
    caixas = caixas_da_regra(dados)
    regra = AutomationRule.find_or_initialize_by(account: @account, name: dados.fetch('nome'))
    regra.update!(
      description: dados['descricao'],
      event_name: dados['evento'] || 'conversation_created',
      conditions: condicoes(dados, caixas).presence || [condicao_de_status_aberto],
      actions: acoes_da_automacao(dados),
      active: caixas != []
    )
    caixas == [] ? "#{regra.name} (nenhum canal desses existe na conta; desativada)" : regra.name
  end

  def acoes_da_automacao(dados)
    dados.fetch('acoes').map do |acao|
      { 'action_name' => acao.fetch('tipo'), 'action_params' => Array(acao['valores'] || acao['valor']) }
    end
  end

  # O avaliador de condições precisa de pelo menos uma linha; sem filtro de
  # canal, a regra vale para toda conversa aberta.
  def condicao_de_status_aberto
    { 'attribute_key' => 'status', 'filter_operator' => 'equal_to', 'values' => ['open'] }
  end
end

# A produção por agente e a distribuição dos tempos, que o dashboard mostra ao
# lado da média: a média engana quando um ticket velho entra na conta.
module Staydesk::Kpi::Producao
  private

  def com_distribuicao(tempos)
    tempos.each { |fila, metricas| metricas.each { |nome, m| m.merge!(distribuicao(nome, fila)) } }
  end

  # Mediana e p90 de uma métrica, nas caixas de um canal de trabalho.
  def distribuicao(metrica, fila)
    nome = Staydesk::KpiService::TEMPOS.key(metrica)
    caixas = caixa_para_fila.select { |_id, chave| chave == fila }.keys
    eventos = ReportingEvent.where(account_id: @account.id, name: nome, inbox_id: caixas, created_at: periodo)
    linha = recortar(eventos, agente: :user_id)
            .pick(Arel.sql('percentile_cont(0.5) within group (order by value), percentile_cont(0.9) within group (order by value)'))
    { mediana_segundos: linha&.first&.round, p90_segundos: linha&.last&.round }
  end

  # Quantas cada agente resolveu no período e os tempos médios dele.
  def producao_por_agente
    eventos = ReportingEvent.where(account_id: @account.id, name: %w[first_response conversation_resolved], created_at: periodo)
    eventos = eventos.where(conversation_id: conversas_filtradas.select(:id)) if filtra_conversa?
    linhas = eventos.where.not(user_id: nil).group(:user_id, :name).pluck(:user_id, :name, Arel.sql('COUNT(*)'), Arel.sql('AVG(value)'))
    mapa = Hash.new { |hash, id| hash[id] = { resolvidas: 0, primeira_resposta_segundos: nil, resolucao_segundos: nil } }
    linhas.each { |linha| anotar_producao(mapa, *linha) }
    mapa
  end

  def anotar_producao(mapa, user_id, nome, quantidade, media)
    if nome == 'conversation_resolved'
      mapa[user_id][:resolvidas] = quantidade
      mapa[user_id][:resolucao_segundos] = media.to_f.round
    else
      mapa[user_id][:primeira_resposta_segundos] = media.to_f.round
    end
  end
end

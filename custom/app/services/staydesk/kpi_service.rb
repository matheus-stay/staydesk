# Os números que a operação olha todo dia, calculados aqui dentro para que o
# dashboard, o MCP e a própria Central leiam a mesma conta. Tudo por período e
# separado por fila de carga, porque chat e ticket não se comparam.
class Staydesk::KpiService
  TEMPOS = { 'first_response' => :primeira_resposta, 'reply_time' => :resposta,
             'conversation_resolved' => :resolucao }.freeze

  def initialize(account:, since: 7.days.ago, ate: Time.current)
    @account = account
    @since = since
    @ate = ate
  end

  def perform
    {
      periodo: { de: @since, ate: @ate },
      csat: csat,
      tempos: tempos,
      fila: fila,
      agentes: agentes,
      resumo_dos_agentes: resumo_dos_agentes
    }
  end

  private

  def periodo
    @since..@ate
  end

  # CSAT no padrão da operação: satisfeito é 4 ou 5.
  def csat
    respostas = CsatSurveyResponse.where(account_id: @account.id, created_at: periodo)
    total = respostas.count
    return { respostas: 0, satisfeitos: 0, neutros: 0, insatisfeitos: 0, percentual: nil, media: nil } if total.zero?

    notas = respostas.group(:rating).count
    satisfeitos = (notas[4] || 0) + (notas[5] || 0)
    {
      respostas: total,
      satisfeitos: satisfeitos,
      neutros: notas[3] || 0,
      insatisfeitos: (notas[1] || 0) + (notas[2] || 0),
      percentual: ((satisfeitos.to_f / total) * 100).round(1),
      media: respostas.average(:rating).to_f.round(2),
      por_agente: csat_por_agente(respostas)
    }
  end

  def csat_por_agente(respostas)
    respostas.where.not(assigned_agent_id: nil).group(:assigned_agent_id).count.map do |user_id, quantidade|
      boas = respostas.where(assigned_agent_id: user_id, rating: [4, 5]).count
      { user_id: user_id, respostas: quantidade, satisfeitos: boas,
        percentual: ((boas.to_f / quantidade) * 100).round(1) }
    end
  end

  # Tempo médio de primeira resposta, de resposta e de resolução, por fila.
  def tempos
    eventos = ReportingEvent.where(account_id: @account.id, name: TEMPOS.keys, created_at: periodo)
                            .group(:name, :inbox_id)
                            .pluck(Arel.sql('name, inbox_id, AVG(value), AVG(value_in_business_hours), COUNT(*)'))
    resultado = Hash.new { |hash, chave| hash[chave] = {} }
    eventos.each do |nome, inbox_id, media, media_comercial, quantidade|
      fila = fila_da_caixa(inbox_id)
      atual = resultado[fila][TEMPOS[nome]] ||= { segundos: 0.0, segundos_no_horario: 0.0, amostras: 0 }
      acumular(atual, media, media_comercial, quantidade)
    end
    resultado.transform_values { |metricas| metricas.transform_values { |m| fechar(m) } }
  end

  def acumular(atual, media, media_comercial, quantidade)
    atual[:segundos] += media.to_f * quantidade
    atual[:segundos_no_horario] += media_comercial.to_f * quantidade
    atual[:amostras] += quantidade
  end

  def fechar(metrica)
    return metrica if metrica[:amostras].zero?

    { segundos: (metrica[:segundos] / metrica[:amostras]).round,
      segundos_no_horario: (metrica[:segundos_no_horario] / metrica[:amostras]).round,
      amostras: metrica[:amostras] }
  end

  def filas
    @filas ||= Staydesk::LoadQueue.resolved(@account)
  end

  def caixa_para_fila
    @caixa_para_fila ||= @account.inboxes.index_with { |caixa| Staydesk::LoadQueue.for_inbox(caixa)&.key }
                                 .transform_keys(&:id)
  end

  def fila_da_caixa(inbox_id)
    caixa_para_fila[inbox_id] || 'sem_fila'
  end

  # O que está esperando agora, por fila, e há quanto tempo espera o mais antigo.
  def fila
    esperando = @account.conversations.open.where(assignee_id: nil)
    por_fila = esperando.group(:inbox_id).count
    mais_antiga = esperando.minimum(:created_at)
    resumo = Hash.new(0)
    por_fila.each { |inbox_id, quantidade| resumo[fila_da_caixa(inbox_id)] += quantidade }
    { total: esperando.count, por_fila: resumo,
      espera_mais_antiga_em_segundos: mais_antiga ? (Time.current - mais_antiga).round : nil }
  end

  # Quem está online agora e quanto tempo cada um passou em cada status no período.
  def agentes
    @agentes ||= begin
      online = conectados
      Staydesk::Kpi::AgentTimeService.new(account: @account, since: @since, ate: @ate).perform.map do |linha|
        linha.merge(online: online.include?(linha[:user_id]))
      end
    end
  end

  # O KPI de tempo online: média entre os agentes que tiveram algum tempo online
  # no período, no total e por dia trabalhado.
  def resumo_dos_agentes
    linhas = agentes.select { |linha| linha[:segundos_online].positive? }
    return { agentes_com_tempo_online: 0, tempo_online_medio_segundos: 0, media_diaria_online_segundos: 0 } if linhas.empty?

    {
      agentes_com_tempo_online: linhas.size,
      tempo_online_medio_segundos: linhas.sum { |linha| linha[:segundos_online] } / linhas.size,
      media_diaria_online_segundos: linhas.sum { |linha| linha[:media_diaria_online_segundos] } / linhas.size
    }
  end

  def conectados
    presentes = OnlineStatusTracker.get_available_users(@account.id) || {}
    presentes.select { |_id, estado| estado == 'online' }.keys.map(&:to_i)
  end
end

# O catálogo da operação dentro do importador: status do ticket, filas de carga,
# status do agente e calendário. Separado para o importador não virar uma classe só.
module Staydesk::ConfigImport::Catalogo
  private

  def importar_status_do_ticket
    secao('status_do_ticket').each_with_index.map do |dados, posicao|
      status = Staydesk::TicketStatus.find_or_initialize_by(account: @account, name: dados.fetch('nome'))
      status.update!(
        base_status: dados.fetch('base'), default_for_base: dados['padrao'] || false,
        apply_on_assign: dados['ao_atribuir'] || false,
        description: dados['descricao'], color: dados['cor'], position: posicao, active: true
      )
      status.name
    end
  end

  # Quais canais contam como qual fila de carga. Sem a seção, vale o padrão do
  # produto (chat pega tudo, e-mail é ticket).
  def importar_filas_de_carga
    dados = secao('filas_de_carga')
    return Staydesk::LoadQueue.keys_for(@account) if dados.blank?

    chaves = dados.each_with_index.map do |fila, posicao|
      registro = Staydesk::LoadQueue.find_or_initialize_by(account: @account, key: fila.fetch('chave'))
      registro.update!(
        name: fila['nome'] || fila.fetch('chave').capitalize,
        channel_types: Array(fila['canais']),
        inbox_ids: caixas_por_nome(fila['caixas']),
        catch_all: fila['coringa'] || false,
        position: posicao
      )
      registro.key
    end
    Staydesk::LoadQueue.where(account: @account).where.not(key: chaves).destroy_all
    chaves
  end

  def importar_status_do_agente
    secao('status_do_agente').each_with_index.map do |dados, posicao|
      status = Staydesk::AgentStatus.find_or_initialize_by(account: @account, name: dados.fetch('nome'))
      status.update!(
        availability: dados['disponibilidade'] || 'online',
        inbox_ids: caixas_por_nome(dados['caixas']),
        capacity: dados['carga'] || {},
        offline_after_seconds: dados.key?('desconexao_segundos') ? dados['desconexao_segundos'] : 300,
        counts_as_online: dados.key?('conta_tempo_online') ? dados['conta_tempo_online'] : (dados['disponibilidade'] || 'online') == 'online',
        color: dados['cor'], position: posicao, active: true
      )
      status.name
    end
    ligar_destinos_de_desconexao
  end

  # O destino só existe depois de todos os status estarem criados.
  def ligar_destinos_de_desconexao
    secao('status_do_agente').each do |dados|
      next if dados['desconexao_para'].blank?

      status = Staydesk::AgentStatus.find_by!(account: @account, name: dados.fetch('nome'))
      status.update!(offline_to_status: Staydesk::AgentStatus.find_by!(account: @account, name: dados['desconexao_para']))
    end
  end

  def importar_calendario
    dados = @config['calendario']
    return if dados.blank?

    calendario = Staydesk::Calendar.find_or_initialize_by(account: @account, name: dados.fetch('nome'))
    calendario.update!(
      timezone: dados['fuso'] || 'America/Sao_Paulo',
      weekly_hours: (dados['horarios'] || []).map { |h| { 'day' => h.fetch('dia'), 'open' => h.fetch('abre'), 'close' => h.fetch('fecha') } },
      holidays: (dados['feriados'] || []).map { |f| { 'date' => f.fetch('data'), 'name' => f.fetch('nome') } }
    )
    calendario
  end
end

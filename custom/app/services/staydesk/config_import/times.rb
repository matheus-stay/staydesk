# Os grupos da operação dentro do importador, com quem está em cada um.
# Separado para o importador não virar uma classe só.
module Staydesk::ConfigImport::Times
  private

  # O grupo pode vir só como nome ("Suporte N1") ou com a lista de quem está
  # nele, que é como se põe muita gente em muitos grupos de uma vez, sem clicar
  # pessoa por pessoa. `agentes` acrescenta; `agentes_exatos: true` faz o grupo
  # ficar igualzinho à lista, tirando quem não está nela.
  def importar_times
    secao('times').map { |dados| importar_time(dados) }
  end

  def importar_time(dados)
    return time!(dados).name unless dados.is_a?(Hash)

    time = time!(dados.fetch('nome'))
    return time.name if dados['agentes'].blank?

    "#{time.name}: #{sincronizar_agentes(time, dados)}"
  end

  def sincronizar_agentes(time, dados)
    pedidos = usuarios_por_email(dados['agentes'])
    entraram = time.add_members(pedidos[:ids] - time.members.ids).size
    sairam = 0
    if dados['agentes_exatos']
      sobrando = time.members.ids - pedidos[:ids]
      time.remove_members(sobrando)
      sairam = sobrando.size
    end
    resumo = ["#{entraram} agente(s) a mais"]
    resumo << "#{sairam} fora" if sairam.positive?
    resumo << "sem conta: #{pedidos[:sem_conta].join(', ')}" if pedidos[:sem_conta].any?
    resumo.join('; ')
  end

  # Aceita e-mail ou id; quem não estiver na conta é devolvido no resumo, para o
  # arquivo não fingir que pôs alguém que não existe.
  def usuarios_por_email(agentes)
    pedidos = Array(agentes).map { |agente| agente.to_s.strip.downcase }
    encontrados = @account.users.where('lower(email) IN (?)', pedidos).pluck(:email, :id)
    { ids: encontrados.map(&:last), sem_conta: pedidos - encontrados.map { |email, _| email.downcase } }
  end

  def time!(nome)
    @account.teams.find_by('lower(name) = ?', nome.strip.downcase) || @account.teams.create!(name: nome.strip)
  end
end

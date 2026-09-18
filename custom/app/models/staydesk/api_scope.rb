# Catálogo de escopos dos tokens de API, lido de custom/config/api_scopes.json.
# Um grupo cobre os controllers cujo caminho começa por um dos prefixos dele, e
# ganha sempre o prefixo mais específico, então "conta" pode ser o guarda-chuva
# sem engolir "conversas".
class Staydesk::ApiScope
  CATALOGO = Rails.root.join('custom/config/api_scopes.json').freeze
  ACOES = %w[leitura escrita].freeze
  METODOS_DE_LEITURA = %w[GET HEAD OPTIONS].freeze

  class << self
    def grupos
      @grupos ||= JSON.parse(File.read(CATALOGO))['grupos']
    end

    def chaves
      grupos.pluck('chave')
    end

    # Todos os escopos possíveis, no formato "grupo:acao".
    def todos
      chaves.flat_map { |chave| ACOES.map { |acao| "#{chave}:#{acao}" } }
    end

    def conhece?(escopo)
      todos.include?(escopo.to_s)
    end

    # Qual grupo responde por este controller: o do prefixo mais longo.
    def grupo_de(controller_path)
      caminho = controller_path.to_s
      candidatos = grupos.flat_map do |grupo|
        grupo['prefixos'].filter_map { |prefixo| [prefixo.length, grupo['chave']] if caminho.start_with?(prefixo) }
      end
      candidatos.max_by(&:first)&.last
    end

    def acao_de(metodo)
      METODOS_DE_LEITURA.include?(metodo.to_s.upcase) ? 'leitura' : 'escrita'
    end

    # O escopo que este pedido exige. Sem grupo, ninguém entra.
    def exigido(controller_path, metodo)
      grupo = grupo_de(controller_path)
      return if grupo.blank?

      "#{grupo}:#{acao_de(metodo)}"
    end
  end
end

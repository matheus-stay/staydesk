# Referência da API do StayDesk, lida de custom/config/api_reference.json.
class Staydesk::ApiReference
  ARQUIVO = Rails.root.join('custom/config/api_reference.json').freeze

  class << self
    def conteudo
      # Em desenvolvimento lê o arquivo a cada vez: editar o JSON aparece na hora.
      return @conteudo = JSON.parse(File.read(ARQUIVO)) if Rails.env.development?

      @conteudo ||= JSON.parse(File.read(ARQUIVO))
    end

    def grupos
      conteudo['grupos']
    end

    def endpoints
      grupos.flat_map { |grupo| grupo['endpoints'] }
    end

    # "GET staydesk/kpis" vira o caminho completo com o parâmetro de conta.
    def caminho_de_rota(endpoint)
      caminho = endpoint['caminho'].gsub(/\{(\w+)\}/) { ":#{Regexp.last_match(1)}" }
      "/api/v1/accounts/:account_id/#{caminho}"
    end
  end
end

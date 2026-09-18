require 'rails_helper'

# A documentação é dado, e este teste é o que impede ela de virar mentira: todo
# endpoint documentado precisa existir nas rotas, e toda rota de staydesk/
# precisa estar documentada.
RSpec.describe Staydesk::ApiReference do
  def rotas_do_staydesk
    Rails.application.routes.routes.filter_map do |rota|
      controller = rota.defaults[:controller]
      next unless controller&.start_with?('api/v1/accounts/staydesk', 'staydesk/zendesk')

      rota.verb.to_s.split('|').map do |verbo|
        [verbo.gsub(/[^A-Z]/, ''), rota.path.spec.to_s.sub('(.:format)', '')]
      end
    end.flatten(1).uniq
  end

  def documentados
    described_class.endpoints.map { |endpoint| [endpoint['metodo'], described_class.caminho_de_rota(endpoint)] }
  end

  it 'documents an endpoint that really exists' do
    inexistentes = documentados.reject { |par| rotas_do_staydesk.include?(par) }

    expect(inexistentes).to be_empty, "documentado mas sem rota: #{inexistentes.map { |m, c| "#{m} #{c}" }.join(', ')}"
  end

  it 'leaves no StayDesk route undocumented' do
    # PUT e PATCH fazem a mesma coisa: documentamos um dos dois.
    equivalente = documentados.flat_map { |metodo, caminho| [[metodo, caminho], [metodo == 'PATCH' ? 'PUT' : 'PATCH', caminho]] }
    faltando = rotas_do_staydesk.reject { |par| equivalente.include?(par) }

    expect(faltando).to be_empty, "rota sem documentação: #{faltando.map { |m, c| "#{m} #{c}" }.join(', ')}"
  end

  it 'asks for a scope the catalog knows, on every endpoint' do
    desconhecidos = described_class.endpoints.map { |e| e['escopo'] }.uniq.reject { |escopo| Staydesk::ApiScope.conhece?(escopo) }

    expect(desconhecidos).to be_empty
  end

end

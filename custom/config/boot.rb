# frozen_string_literal: true

# Registra os caminhos da camada StayDesk na aplicação Rails: autoload, views,
# rotas, migrations, tarefas rake e initializers de custom/. Chamado de
# config/application.rb, o único ponto de montagem do backend.
require_relative '../../lib/chatwoot_app'

module StaydeskBoot
  # No núcleo, ChatwootApp.extensions devolve %w[enterprise custom] só porque
  # custom/ existe, injetando os módulos Enterprise mesmo com DISABLE_ENTERPRISE.
  # Aqui enterprise só entra quando ChatwootApp.enterprise? é verdadeiro.
  module Extensions
    def extensions
      enterprise? ? %w[enterprise custom] : %w[custom]
    end
  end

  def self.configure(config)
    ChatwootApp.singleton_class.prepend(Extensions)
    root = Rails.root
    config.eager_load_paths << root.join('custom/lib')
    config.eager_load_paths += Dir[root.join('custom/app/*').to_s]
    montar_views(config)
    montar_caminhos(config, root)
    Dir[root.join('custom/config/initializers/**/*.rb').to_s].each { |f| require f }
  end

  def self.montar_caminhos(config, root)
    config.paths['config/routes.rb'] << 'custom/config/routes.rb'
    config.paths['db/migrate'] << 'custom/db/migrate'
    config.paths['lib/tasks'] << 'custom/lib/tasks'
    # Depois dos textos do núcleo, para as nossas chaves vencerem as dele.
    config.i18n.load_path += Dir[root.join('custom/config/locales/**/*.yml').to_s]
  end

  # Sem Enterprise, as telas dele saem do caminho: elas continuam no disco e o
  # produto as coloca na frente das do núcleo, mesmo com a edição desligada. O
  # modelo de e-mail de confirmação, por exemplo, chama um recurso que só existe
  # na edição paga, e o convite de agente morria no envio sem aviso nenhum.
  def self.montar_views(config)
    unless ChatwootApp.enterprise?
      config.paths['app/views'] = config.paths['app/views'].to_a.reject { |caminho| caminho.end_with?('enterprise/app/views') }
    end
    config.paths['app/views'].unshift('custom/app/views')
  end
end

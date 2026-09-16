# frozen_string_literal: true

# Registra os caminhos da camada StayDesk na aplicação Rails: autoload, views,
# rotas, migrations, tarefas rake e initializers de custom/. Chamado de
# config/application.rb, o único ponto de montagem do backend.
module StaydeskBoot
  def self.configure(config)
    root = Rails.root
    config.eager_load_paths << root.join('custom/lib')
    config.eager_load_paths += Dir[root.join('custom/app/*').to_s]
    config.paths['app/views'].unshift('custom/app/views')
    config.paths['config/routes.rb'] << 'custom/config/routes.rb'
    config.paths['db/migrate'] << 'custom/db/migrate'
    config.paths['lib/tasks'] << 'custom/lib/tasks'
    Dir[root.join('custom/config/initializers/**/*.rb').to_s].each { |f| require f }
  end
end

# Cria ou atualiza views por time a partir de definições em YAML (rails staydesk:team_views:importar).
# Cada definição: name, description, color, icon, sort_by, columns, teams (nomes) e query.
class Staydesk::TeamViewImportService
  def initialize(account:, definitions:)
    @account = account
    @definitions = definitions
  end

  def perform
    @definitions.each_with_index.map do |definition, position|
      view = Staydesk::TeamView.find_or_initialize_by(account: @account, name: definition.fetch('name'))
      view.update!(
        description: definition['description'],
        color: definition['color'],
        icon: definition['icon'],
        sort_by: definition['sort_by'],
        columns: definition['columns'] || Staydesk::TeamView::DEFAULT_COLUMNS,
        query: definition.fetch('query'),
        team_ids: team_ids_for(definition['teams'] || []),
        position: position
      )
      view
    end
  end

  private

  def team_ids_for(names)
    # Sem diferenciar maiúsculas: o nome do grupo é gravado como foi escrito.
    names.map { |name| @account.teams.find_by!('lower(name) = ?', name.strip.downcase).id }
  end
end

# Resolve a área de trabalho de um usuário: padrão do produto, depois o padrão da
# conta, depois os times do usuário (união das listas, ordem do primeiro time),
# depois a sobreposição do papel. Listas vazias herdam; listas presentes valem.
class Staydesk::WorkspaceResolver
  PRODUCT_DEFAULT = {
    'menu' => %w[Inbox Conversation Calls Contacts Reports Captain Companies Campaigns Portals],
    'list' => { 'layout' => 'cards', 'columns' => Staydesk::TeamView::DEFAULT_COLUMNS, 'sort_by' => 'last_activity_at_desc', 'page_size' => 25 },
    'conversation' => { 'fields' => %w[assignee team priority labels], 'panels' => [], 'apps' => nil },
    'macros' => { 'mode' => 'all', 'ids' => [] },
    'composer' => { 'submit_as' => true, 'after_send' => 'stay' }
  }.freeze

  SECTIONS = %w[menu list conversation macros composer].freeze

  def initialize(user:, account:)
    @user = user
    @account = account
  end

  def resolve
    config = deep_merge(PRODUCT_DEFAULT, account_default)
    team_configs.each { |team_config| config = merge_team(config, team_config) }
    config = deep_merge(config, role_override(config))
    config.slice(*SECTIONS).merge('role' => role, 'team_ids' => team_ids)
  end

  private

  def role
    @account.account_users.find_by(user_id: @user.id)&.role || 'agent'
  end

  def team_ids
    @team_ids ||= @user.teams.where(account_id: @account.id).ids
  end

  def account_default
    Staydesk::TeamWorkspace.account_default.find_by(account: @account)&.config || {}
  end

  def team_configs
    Staydesk::TeamWorkspace.where(account: @account, team_id: team_ids).order(:team_id).map(&:config)
  end

  # Time por time: chaves escalares vencem, listas fazem união preservando a ordem já vista.
  def merge_team(config, team_config)
    deep_merge(config, team_config) do |_key, current, incoming|
      current.is_a?(Array) && incoming.is_a?(Array) ? (current | incoming) : incoming
    end
  end

  def role_override(config)
    config.dig('roles', role) || {}
  end

  def deep_merge(base, other, &block)
    base.merge(other.except('roles')) do |key, current, incoming|
      if current.is_a?(Hash) && incoming.is_a?(Hash)
        deep_merge(current, incoming, &block)
      elsif block
        block.call(key, current, incoming)
      else
        incoming
      end
    end.merge('roles' => (base['roles'] || {}).merge(other['roles'] || {}))
  end
end

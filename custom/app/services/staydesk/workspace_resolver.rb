# Resolve a área de trabalho de um usuário: padrão do produto, depois o padrão da
# conta, depois os times do usuário (união das listas, ordem do primeiro time),
# depois a sobreposição do papel. Listas vazias herdam; listas presentes valem.
class Staydesk::WorkspaceResolver
  PRODUCT_DEFAULT = {
    # Campanhas e central de ajuda ficam de fora por decisão de produto (2026-09-17);
    # para trazer de volta, basta listá-las no padrão da conta ou do time.
    'menu' => %w[Inbox Conversation Calls Contacts Reports Captain Companies],
    'conversation_menu' => %w[All Mentions Participating Unattended Folders StaydeskTeamViews Teams Channels],
    'list' => { 'layout' => 'cards', 'columns' => Staydesk::TeamView::DEFAULT_COLUMNS, 'sort_by' => 'last_activity_at_desc',
                'page_size' => 25, 'tabs' => %w[me unassigned all], 'hide_when_open' => false },
    # O painel da direita nasce com o histórico do contato; o painel da esquerda
    # (campos do ticket) já cobre agente, time, prioridade e etiquetas.
    'conversation' => { 'fields' => %w[assignee team priority labels],
                        'panels' => %w[previous_conversation contact_attributes contact_notes shared_files
                                       conversation_info conversation_participants macros],
                        'apps' => nil, 'side_apps' => [] },
    'macros' => { 'mode' => 'all', 'ids' => [] },
    'composer' => { 'submit_as' => true, 'after_send' => 'stay' }
  }.freeze

  SECTIONS = %w[menu conversation_menu list conversation macros composer].freeze

  def initialize(user:, account:)
    @user = user
    @account = account
  end

  # Cada time vale o que define e herda o resto; com vários times, as listas se unem
  # (ordem do primeiro) e os escalares ficam com o último.
  def resolve
    base = deep_merge(PRODUCT_DEFAULT, account_default)
    effective = team_configs.map { |team_config| deep_merge(base, team_config) }
    config = effective.empty? ? base : effective.reduce { |merged, team_config| merge_team(merged, team_config) }
    config = deep_merge(config, role_override(config))
    config.slice(*SECTIONS).merge('role' => role, 'team_ids' => team_ids)
  end

  private

  def role
    account_user = @account.account_users.find_by(user_id: @user.id)
    return 'light' if account_user&.staydesk_light?

    account_user&.role || 'agent'
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

  # Entre times: chaves escalares vencem, listas fazem união preservando a ordem já vista.
  def merge_team(config, team_config)
    deep_merge(config, team_config) do |_key, current, incoming|
      current.is_a?(Array) && incoming.is_a?(Array) ? (current | incoming) : incoming
    end
  end

  def role_override(config)
    config.dig('roles', role) || {}
  end

  def deep_merge(base, other, &block)
    base.merge(other) do |key, current, incoming|
      if current.is_a?(Hash) && incoming.is_a?(Hash)
        deep_merge(current, incoming, &block)
      elsif block
        yield(key, current, incoming)
      else
        incoming
      end
    end
  end
end

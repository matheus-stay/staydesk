# == Schema Information
#
# Table name: staydesk_team_workspaces
#
#  id         :bigint           not null, primary key
#  config     :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  team_id    :bigint           (nulo = padrão da conta)
#
# A configuração da área de trabalho de um time (custom/config/schemas/team_workspace.json).
class Staydesk::TeamWorkspace < ApplicationRecord
  self.table_name = 'staydesk_team_workspaces'

  SCHEMA_PATH = Rails.root.join('custom/config/schemas/team_workspace.json')

  belongs_to :account
  belongs_to :team, optional: true

  validates :team_id, uniqueness: { scope: :account_id }
  validate :config_matches_schema

  scope :account_default, -> { where(team_id: nil) }

  def self.schema
    @schema ||= JSON.parse(SCHEMA_PATH.read)
  end

  def self.schemer
    @schemer ||= JSONSchemer.schema(schema)
  end

  private

  def config_matches_schema
    self.class.schemer.validate(config).each do |error|
      errors.add(:config, "#{error['data_pointer'].presence || '/'} #{error['type']}")
    end
  end
end

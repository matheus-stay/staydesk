# == Schema Information
#
# Table name: staydesk_calendars
#
#  id           :bigint           not null, primary key
#  holidays     :jsonb            not null  ([{ "date": "2026-12-25", "name": "Natal" }])
#  name         :string           not null
#  timezone     :string           default("America/Sao_Paulo"), not null
#  weekly_hours :jsonb            not null  ([{ "day": 1, "open": "09:00", "close": "18:00" }], 0 = domingo)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#
# Horário comercial com feriados: é o relógio do SLA quando a política aponta para um calendário.
class Staydesk::Calendar < ApplicationRecord
  self.table_name = 'staydesk_calendars'

  belongs_to :account
  has_many :sla_policies, class_name: 'Staydesk::SlaPolicy', foreign_key: :calendar_id, dependent: :nullify, inverse_of: :calendar

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :timezone, inclusion: { in: ->(_) { ActiveSupport::TimeZone.all.map { |zone| zone.tzinfo.name } } }
  validate :weekly_hours_shape

  def business_time
    Staydesk::Sla::BusinessTime.new(self)
  end

  private

  def weekly_hours_shape
    return if weekly_hours.is_a?(Array) && weekly_hours.all? { |slot| slot.is_a?(Hash) && slot['day'].to_s =~ /\A[0-6]\z/ && slot['open'].to_s =~ /\A\d{2}:\d{2}\z/ && slot['close'].to_s =~ /\A\d{2}:\d{2}\z/ }

    errors.add(:weekly_hours, 'must be a list of { day: 0-6, open: HH:MM, close: HH:MM }')
  end
end

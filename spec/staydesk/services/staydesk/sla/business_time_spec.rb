require 'rails_helper'

RSpec.describe Staydesk::Sla::BusinessTime do
  let(:account) { create(:account) }
  let(:calendar) do
    Staydesk::Calendar.create!(
      account: account, name: 'Comercial', timezone: 'America/Sao_Paulo',
      weekly_hours: (1..5).map { |day| { 'day' => day, 'open' => '09:00', 'close' => '18:00' } },
      holidays: [{ 'date' => '2026-09-18', 'name' => 'Feriado de teste' }]
    )
  end
  let(:clock) { described_class.new(calendar) }
  let(:zone) { ActiveSupport::TimeZone['America/Sao_Paulo'] }

  it 'adds minutes inside the same business day' do
    expect(clock.add_minutes(zone.parse('2026-09-16 10:00'), 60)).to eq(zone.parse('2026-09-16 11:00'))
  end

  it 'carries the remainder to the next business day' do
    expect(clock.add_minutes(zone.parse('2026-09-16 17:30'), 60)).to eq(zone.parse('2026-09-17 09:30'))
  end

  it 'skips holidays and weekends' do
    # 17/09 quinta às 17:30 + 60 min: pula o feriado de sexta (18/09) e o fim de semana
    expect(clock.add_minutes(zone.parse('2026-09-17 17:30'), 60)).to eq(zone.parse('2026-09-21 09:30'))
  end

  it 'starts counting at the next opening when outside business hours' do
    expect(clock.add_minutes(zone.parse('2026-09-16 22:00'), 30)).to eq(zone.parse('2026-09-17 09:30'))
  end

  it 'measures elapsed business seconds' do
    expect(clock.elapsed_seconds(zone.parse('2026-09-16 17:00'), zone.parse('2026-09-17 10:00'))).to eq(2 * 3600)
  end

  it 'is a plain clock without a calendar' do
    from = Time.zone.parse('2026-09-19 22:00')
    expect(described_class.wall_clock.add_minutes(from, 90)).to eq(from + 90.minutes)
  end
end

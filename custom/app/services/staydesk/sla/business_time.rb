# Relógio do SLA. Com calendário, só corre nos horários da semana, fora dos feriados,
# no fuso do calendário; sem calendário, é relógio de parede.
class Staydesk::Sla::BusinessTime
  MINUTE = 60

  def self.wall_clock
    new(nil)
  end

  def initialize(calendar)
    @calendar = calendar
  end

  def wall_clock?
    @calendar.nil?
  end

  # Instante em que `minutes` minutos úteis terão passado a partir de `from`.
  def add_minutes(from, minutes)
    return from + minutes.minutes if wall_clock?

    remaining = minutes * MINUTE
    cursor = from.in_time_zone(zone)
    365.times do
      slot_end = current_slot_end(cursor)
      if slot_end.nil?
        cursor = next_slot_start(cursor)
        return nil if cursor.nil?

        next
      end
      available = slot_end - cursor
      return cursor + remaining if remaining <= available

      remaining -= available
      cursor = next_slot_start(slot_end)
      return nil if cursor.nil?
    end
    nil
  end

  # Segundos úteis decorridos entre dois instantes.
  def elapsed_seconds(from, to)
    return [to - from, 0].max if wall_clock?

    total = 0
    cursor = from.in_time_zone(zone)
    limit = to.in_time_zone(zone)
    365.times do
      break if cursor >= limit

      slot_end = current_slot_end(cursor)
      if slot_end.nil?
        cursor = next_slot_start(cursor)
        break if cursor.nil?

        next
      end
      total += [slot_end, limit].min - cursor
      cursor = next_slot_start(slot_end)
      break if cursor.nil?
    end
    total
  end

  private

  def zone
    @zone ||= ActiveSupport::TimeZone[@calendar.timezone]
  end

  def holiday?(date)
    @holidays ||= @calendar.holidays.map { |h| h['date'] }.to_set
    @holidays.include?(date.iso8601)
  end

  def slots_for(date)
    return [] if holiday?(date)

    @calendar.weekly_hours
             .select { |slot| slot['day'].to_i == date.wday }
             .map { |slot| [zone.parse("#{date.iso8601} #{slot['open']}"), zone.parse("#{date.iso8601} #{slot['close']}")] }
             .select { |open_at, close_at| close_at > open_at }
             .sort_by(&:first)
  end

  # Fim do intervalo útil em que `time` está, ou nil se está fora de horário.
  def current_slot_end(time)
    slots_for(time.to_date).each do |open_at, close_at|
      return close_at if time >= open_at && time < close_at
    end
    nil
  end

  # Início do próximo intervalo útil depois de `time`.
  def next_slot_start(time)
    date = time.to_date
    60.times do
      slots_for(date).each do |open_at, _close_at|
        return open_at if open_at > time
      end
      date += 1
    end
    nil
  end
end

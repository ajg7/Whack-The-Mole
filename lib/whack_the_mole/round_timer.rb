# frozen_string_literal: true

module WhackTheMole
  class RoundTimer
    attr_reader :started_at

    def initialize(started_at:, duration_ms:)
      @started_at = started_at
      @duration_ms = duration_ms
    end

    def remaining_ms(now)
      (@duration_ms - (now - started_at)).clamp(0, @duration_ms)
    end

    def expired?(now)
      remaining_ms(now).zero?
    end

    def elapsed_fraction(now)
      1.0 - (remaining_ms(now).to_f / @duration_ms)
    end

    def seconds_left(now)
      (remaining_ms(now) / 1000.0).ceil
    end

    def clock_label(now)
      minutes, seconds = seconds_left(now).divmod(60)
      format('%<minutes>d:%<seconds>02d', minutes:, seconds:)
    end
  end
end

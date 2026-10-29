# frozen_string_literal: true

module WhackTheMole
  class Hammer
    FRAMES = 3

    def self.hit_point(x, y)
      dx, dy = Config::HAMMER_HEAD_OFFSET
      [x + dx, y + dy]
    end

    def initialize
      @swung_at = nil
    end

    def swing(now)
      @swung_at = now
    end

    def frame(now)
      return 0 unless @swung_at

      step = (now - @swung_at) / Config::SWING_FRAME_MS
      step < FRAMES ? step : 0
    end
  end
end

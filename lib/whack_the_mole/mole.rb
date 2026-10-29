# frozen_string_literal: true

module WhackTheMole
  class Mole
    SETTLED_FRAME = 3
    TRANSITION_MS = 3 * Config::RISE_FRAME_MS
    DROP_MS = 3 * Config::DROP_FRAME_MS

    attr_reader :hole

    def initialize(hole:, spawned_at:, up_ms:)
      @hole = hole
      @spawned_at = spawned_at
      @up_ms = up_ms
      @whacked_at = nil
    end

    def whack(now)
      @whacked_at = now
    end

    def whacked?
      !@whacked_at.nil?
    end

    def phase(now)
      return whacked_phase(now) if whacked?

      age = now - @spawned_at
      if age < TRANSITION_MS then :rising
      elsif age < TRANSITION_MS + @up_ms then :up
      elsif age < (2 * TRANSITION_MS) + @up_ms then :hiding
      else :gone
      end
    end

    def frame(now)
      case phase(now)
      when :rising then (now - @spawned_at) / Config::RISE_FRAME_MS
      when :up then SETTLED_FRAME
      when :hiding then 2 - ((now - @spawned_at - TRANSITION_MS - @up_ms) / Config::RISE_FRAME_MS)
      when :dropping then 2 - ((now - @whacked_at) / Config::DROP_FRAME_MS)
      else 0
      end
    end

    def hittable?(now)
      !whacked? && %i[rising up].include?(phase(now))
    end

    def gone?(now)
      phase(now) == :gone
    end

    def contains?(x, y)
      x.between?(left, left + Config::DRAWN_SIZE) && y.between?(top, top + Config::DRAWN_SIZE)
    end

    def left
      hole.x - (Config::DRAWN_SIZE / 2)
    end

    def top
      hole.y - Config::SPRITE_ABOVE_HOLE
    end

    private

    def whacked_phase(now)
      now - @whacked_at < DROP_MS ? :dropping : :gone
    end
  end
end

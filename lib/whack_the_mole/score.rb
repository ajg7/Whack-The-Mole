# frozen_string_literal: true

module WhackTheMole
  class Score
    attr_reader :hits, :misses

    def initialize
      @hits = 0
      @misses = 0
    end

    def hit!
      @hits += 1
    end

    def miss!
      @misses += 1
    end

    def total
      hits - misses
    end
  end
end

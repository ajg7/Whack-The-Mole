# frozen_string_literal: true

require_relative '../test_helper'

module WhackTheMole
  class HoleScoreTest < Minitest::Test
    def test_grid_has_nine_distinct_holes
      grid = Hole.grid

      assert_equal 9, grid.size
      assert_equal 9, grid.uniq.size
    end

    def test_score_can_go_negative
      score = Score.new
      score.hit!
      2.times { score.miss! }

      assert_equal(-1, score.total)
      assert_equal 1, score.hits
      assert_equal 2, score.misses
    end
  end
end

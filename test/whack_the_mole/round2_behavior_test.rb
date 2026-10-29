# frozen_string_literal: true

require 'tmpdir'
require_relative '../test_helper'

module WhackTheMole
  class Round2BehaviorTest < Minitest::Test
    OFFSET_X, OFFSET_Y = Config::HAMMER_HEAD_OFFSET

    def setup
      @dir = Dir.mktmpdir
      @path = File.join(@dir, 'highscore.json')
      @game = Game.new(random: Random.new(7), high_score: HighScore.new(path: @path))
      @game.click(0, 0, now: 0)
      @game.update(3000)
    end

    def teardown
      FileUtils.remove_entry(@dir)
    end

    def click_head(x, y, now)
      @game.click(x - OFFSET_X, y - OFFSET_Y, now: now)
    end

    def test_second_click_on_whacked_mole_later_is_ignored
      m = @game.moles.first
      click_head(m.hole.x, m.hole.y, 3100)

      assert_nil click_head(m.hole.x, m.hole.y, 3120)
      assert_equal [1, 0, 1], [@game.score.hits, @game.score.misses, @game.score.total]
    end

    def test_lockout_boundary_after_game_over
      @game.update(63_000)
      @game.click(300, 300, now: 63_000 + Config::GAME_OVER_LOCKOUT_MS - 1)

      assert_equal :game_over, @game.state
      @game.click(300, 300, now: 63_000 + Config::GAME_OVER_LOCKOUT_MS)

      assert_equal :countdown, @game.state
    end

    def test_ignored_lockout_click_does_not_change_score
      click_head(1, 1, 3100)
      @game.update(63_000)
      @game.click(300, 300, now: 63_100)

      assert_equal(-1, @game.score.total)
    end

    def test_explicit_start_bypasses_lockout
      @game.update(63_000)
      @game.start(63_001)

      assert_equal :countdown, @game.state
    end

    def test_hit_box_is_tighter_than_the_full_sprite
      m = @game.moles.first
      far_corner = (Config::DRAWN_SIZE / 2) - 2

      assert_equal :miss, click_head(m.hole.x + far_corner, m.hole.y, 3300)
    end

    def test_negative_or_fractional_stored_best_is_zero
      ['{"best":-5}', '{"best":2.5}', '{"best":"9"}'].each do |json|
        File.write(@path, json)

        assert_equal 0, HighScore.new(path: @path).best, json
      end
    end
  end
end

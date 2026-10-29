# frozen_string_literal: true

require 'tmpdir'
require_relative '../test_helper'

module WhackTheMole
  class GameRulesTest < Minitest::Test
    def setup
      @dir = Dir.mktmpdir
      @game = Game.new(random: Random.new(1), high_score: HighScore.new(path: File.join(@dir, 'highscore.json')))
    end

    def teardown
      FileUtils.remove_entry(@dir)
    end

    def test_game_over_click_is_ignored_during_lockout
      play(0)
      @game.update(63_000)
      @game.click(0, 0, now: 63_000 + Config::GAME_OVER_LOCKOUT_MS - 1)

      assert_equal :game_over, @game.state
      @game.click(0, 0, now: 63_000 + Config::GAME_OVER_LOCKOUT_MS)

      assert_equal :countdown, @game.state
    end

    def test_hit_uses_the_hammer_head_offset
      play(0)
      mole = @game.moles.first
      dx, dy = Config::HAMMER_HEAD_OFFSET
      right = mole.hole.x + 16
      bottom = mole.hole.y + 12

      assert_equal :hit, @game.click(right - dx, bottom - dy, now: 3100)
    end

    def test_hammer_offset_edge_just_outside_is_a_miss
      play(0)
      mole = @game.moles.first
      dx, dy = Config::HAMMER_HEAD_OFFSET

      assert_equal :miss, @game.click(mole.hole.x + 17 - dx, mole.hole.y - dy, now: 3100)
    end

    private

    def play(now)
      @game.start(now)
      @game.update(now + Config::COUNTDOWN_MS)
    end
  end
end

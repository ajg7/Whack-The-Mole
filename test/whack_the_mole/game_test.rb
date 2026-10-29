# frozen_string_literal: true

require 'tmpdir'
require_relative '../test_helper'

module WhackTheMole
  class GameTest < Minitest::Test
    def setup
      @dir = Dir.mktmpdir
      @high_score = HighScore.new(path: File.join(@dir, 'highscore.json'))
      @game = Game.new(random: Random.new(1), high_score: @high_score)
    end

    def teardown
      FileUtils.remove_entry(@dir)
    end

    def test_title_click_starts_countdown_then_play_then_game_over
      assert_equal :title, @game.state
      @game.click(0, 0, now: 0)

      assert_equal :countdown, @game.state
      @game.update(2999)

      assert_equal :countdown, @game.state
      @game.update(3000)

      assert_equal :playing, @game.state
      @game.update(63_000)

      assert_equal :game_over, @game.state
    end

    def test_clicks_during_countdown_are_not_scored
      @game.click(0, 0, now: 0)

      assert_nil @game.click(0, 0, now: 100)
      assert_equal 0, @game.score.total
      assert_equal 0, @game.score.misses
    end

    def test_countdown_and_clock_labels
      @game.start(0)

      assert_equal([3, 2, 1], [0, 1000, 2000].map { |now| @game.countdown_number(now) })
      assert_equal '1:00', @game.clock_label(500)
    end

    def test_at_most_two_moles_in_distinct_holes
      play(0)
      (3000..40_000).step(16) do |now|
        @game.update(now)

        assert_operator @game.moles.size, :<=, 2
        assert_equal @game.moles.size, @game.moles.map(&:hole).uniq.size
      end
    end

    def test_hit_scores_once_and_adds_popup
      play(0)
      mole = @game.moles.first

      assert_equal :hit, @game.click(mole.hole.x, mole.hole.y, now: 3100)
      assert_equal 1, @game.score.hits
      assert_equal 1, @game.popups.size
      assert_equal :miss, @game.click(mole.hole.x, mole.hole.y, now: 3110)
      assert_equal 0, @game.score.total
    end

    def test_miss_can_go_negative
      play(0)

      assert_equal :miss, @game.click(0, 0, now: 3100)
      assert_equal(-1, @game.score.total)
    end

    def test_spawn_interval_and_escape_cost_nothing
      play(0)

      assert_equal 1, @game.moles.size
      @game.update(3499)

      assert_equal 1, @game.moles.size
      @game.update(3500)

      assert_equal 2, @game.moles.size
      @game.update(5000)

      assert_equal 0, @game.score.total
    end

    def test_game_over_records_best_and_click_restarts
      play(0)
      @game.click(0, 0, now: 3100)
      @game.update(63_000)

      assert_equal 0, @game.best
      @game.click(0, 0, now: 64_000)

      assert_equal :countdown, @game.state
      assert_equal 0, @game.score.misses
      assert_empty @game.moles
    end

    def test_step_size_does_not_change_the_outcome
      states = [16, 33].map do |step|
        game = Game.new(random: Random.new(1), high_score: @high_score)
        game.start(0)
        (0..70_000).step(step) { |now| game.update(now) }
        game.state
      end

      assert_equal %i[game_over game_over], states
    end

    private

    def play(now)
      @game.start(now)
      @game.update(now + Config::COUNTDOWN_MS)
    end
  end
end

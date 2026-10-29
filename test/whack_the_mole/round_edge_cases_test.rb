# frozen_string_literal: true

require 'tmpdir'
require_relative '../test_helper'

module WhackTheMole
  class RoundEdgeCasesTest < Minitest::Test
    OFFSET_X, OFFSET_Y = Config::HAMMER_HEAD_OFFSET

    def setup
      @dir = Dir.mktmpdir
      @path = File.join(@dir, 'highscore.json')
      @game = started_game
    end

    def teardown
      FileUtils.remove_entry(@dir)
    end

    def started_game
      game = Game.new(random: Random.new(7), high_score: HighScore.new(path: @path))
      game.click(0, 0, now: 0)
      game.update(3000)
      game
    end

    def click_head(game, x, y, now)
      game.click(x - OFFSET_X, y - OFFSET_Y, now: now)
    end

    def mole
      @game.moles.first
    end

    def test_never_more_than_two_moles_or_shared_hole
      seen = (3000..20_000).step(7).map do |t|
        @game.update(t)
        @game.moles.map(&:hole)
      end

      assert(seen.all? { |holes| holes.size <= 2 && holes.uniq.size == holes.size })
      assert(seen.any? { |holes| holes.size == 2 })
    end

    def test_second_mole_spawns_after_500ms
      @game.update(3499)

      assert_equal 1, @game.moles.size
      @game.update(3500)

      assert_equal 2, @game.moles.size
    end

    def test_same_seed_gives_same_first_spawn
      assert_equal mole.hole, started_game.moles.first.hole
    end

    def test_large_time_step_does_not_crash_or_overspawn
      @game.update(10_000)

      assert_operator @game.moles.size, :<=, 2
      @game.update(1_000_000)

      assert_equal :game_over, @game.state
    end

    def test_tiny_time_steps_do_not_spawn_early
      (3001..3499).each { |t| @game.update(t) }

      assert_equal 1, @game.moles.size
    end

    def test_up_time_is_1200_at_start
      assert_equal :up, mole.phase(3000 + Mole::TRANSITION_MS + 1199)
      assert_equal :hiding, mole.phase(3000 + Mole::TRANSITION_MS + 1200)
    end

    def test_up_time_is_near_600_at_end_of_round
      first_seen = {}
      (3000..62_990).step(10) do |t|
        @game.update(t)
        @game.moles.each { |m| first_seen[m] ||= t }
      end
      late, seen_at = first_seen.max_by { |_, t| t }

      refute_equal :up, late.phase(seen_at + Mole::TRANSITION_MS + 700)
    end

    def test_timer_labels
      assert_equal '1:00', @game.clock_label(3000)
      assert_equal '1:00', @game.clock_label(3001)
      assert_equal '0:59', @game.clock_label(4000)
      assert_equal '0:01', @game.clock_label(62_999)
      assert_equal '0:00', @game.clock_label(63_000)
    end

    def test_timer_exactly_zero_ends_round_one_ms_before_does_not
      @game.update(62_999)

      assert_equal :playing, @game.state
      @game.update(63_000)

      assert_equal :game_over, @game.state
    end

    def test_click_after_game_over_restarts_without_scoring
      @game.update(63_000)
      @game.click(300, 300, now: 64_000)

      assert_equal :countdown, @game.state
      assert_equal 0, @game.score.total
    end

    def test_game_over_clears_moles_and_update_after_is_harmless
      @game.update(63_000)
      @game.update(70_000)

      assert_empty @game.moles
      assert_equal :game_over, @game.state
    end

    def test_restart_resets_everything
      click_head(@game, 1, 1, 3100)
      @game.update(63_000)
      @game.start(64_000)

      assert_equal :countdown, @game.state
      assert_equal [0, 0], [@game.score.total, @game.score.misses]
      assert_empty @game.moles
      assert_equal '1:00', @game.clock_label(64_000)
      @game.update(67_000)

      assert_equal :playing, @game.state
      assert_equal 1, @game.moles.size
    end
  end
end

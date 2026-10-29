# frozen_string_literal: true

require 'tmpdir'
require_relative '../test_helper'

module WhackTheMole
  class HitEdgeCasesTest < Minitest::Test
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

    def test_hit_on_center_and_just_inside_edges
      [[0, 0], [-32, -64], [16, 12]].each do |dx, dy|
        game = started_game
        m = game.moles.first

        assert_equal :hit, click_head(game, m.hole.x + dx, m.hole.y + dy, 3300)
      end
    end

    def test_just_outside_is_a_miss
      [[-33, 0], [17, 0], [0, -65], [0, 13]].each do |dx, dy|
        game = started_game
        m = game.moles.first

        assert_equal :miss, click_head(game, m.hole.x + dx, m.hole.y + dy, 3300), [dx, dy].inspect
        assert_equal(-1, game.score.total)
      end
    end

    def test_click_on_empty_hole_and_grass_is_minus_one
      free = Hole.grid.find { |h| @game.moles.none? { |m| m.hole == h } }

      assert_equal :miss, click_head(@game, free.x, free.y, 3100)
      assert_equal :miss, click_head(@game, 1, 1, 3100)
      assert_equal(-2, @game.score.total)
    end

    def test_score_can_go_negative_and_hits_misses_are_separate
      3.times { click_head(@game, 1, 1, 3100) }

      assert_equal(-3, @game.score.total)
      assert_equal 3, @game.score.misses
      assert_equal 0, @game.score.hits
    end

    def test_double_hit_in_one_frame_scores_once
      m = mole
      click_head(@game, m.hole.x, m.hole.y, 3100)
      click_head(@game, m.hole.x, m.hole.y, 3100)

      assert_equal 1, @game.score.hits
      assert_equal 0, @game.score.misses
    end

    def test_hiding_mole_cannot_be_hit
      m = mole
      hiding_at = 3000 + Mole::TRANSITION_MS + 1200 + 10

      assert_equal :hiding, m.phase(hiding_at)
      assert_nil click_head(@game, m.hole.x, m.hole.y, hiding_at)
      assert_equal 0, @game.score.total
      assert_equal 0, @game.score.misses
    end

    def test_whacked_mole_drops_and_gives_popup
      m = mole
      click_head(@game, m.hole.x, m.hole.y, 3100)

      assert_equal :dropping, m.phase(3110)
      assert_equal 1, @game.popups.size
      assert_equal :gone, m.phase(3100 + Mole::DROP_MS)
    end

    def test_hammer_swing_has_three_frames_and_returns_to_rest
      hammer = Hammer.new
      hammer.swing(1000)

      frames = [1000, 1050, 1100, 1150].map { |t| hammer.frame(t) }

      assert_equal [0, 1, 2, 0], frames
    end

    def test_popup_fades_and_expires
      popup = Popup.new(x: 0, y: 0, started_at: 100)

      assert_equal 255, popup.alpha(100)
      refute popup.expired?(699)
      assert popup.expired?(700)
      assert_equal 0, popup.alpha(700)
    end

    def test_mole_frames_stay_in_range_through_lifecycle
      m = Mole.new(hole: Hole.grid.first, spawned_at: 0, up_ms: 600)
      frames = (0..2000).map { |t| m.frame(t) }

      assert(frames.all? { |f| (0..3).cover?(f) })
      assert_equal 0, m.frame(0)
      assert_equal 3, m.frame(Mole::TRANSITION_MS)
    end

    def test_countdown_numbers
      game = Game.new(random: Random.new(1), high_score: HighScore.new(path: @path))
      game.click(0, 0, now: 0)

      assert_equal 3, game.countdown_number(0)
      assert_equal 2, game.countdown_number(1000)
      assert_equal 1, game.countdown_number(2999)
    end
  end
end

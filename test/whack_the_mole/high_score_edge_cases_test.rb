# frozen_string_literal: true

require 'tmpdir'
require_relative '../test_helper'

module WhackTheMole
  class HighScoreEdgeCasesTest < Minitest::Test
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

    def test_best_score_recorded_and_persisted
      click_head(@game, mole.hole.x, mole.hole.y, 3100)
      @game.update(63_000)

      assert_equal 1, @game.best
      assert_equal 1, HighScore.new(path: @path).best
    end

    def test_lower_score_does_not_overwrite_best
      File.write(@path, '{"best":5}')
      game = started_game
      game.update(63_000)

      assert_equal 5, game.best
    end

    def test_missing_high_score_file_is_zero
      assert_equal 0, HighScore.new(path: File.join(@dir, 'nope', 'x.json')).best
    end

    def test_corrupt_high_score_files_are_zero
      ['', '{', 'garbage', '[]', 'null', '{"best":"x"}', '{"best":1.5}', "\xFF\xFE\x00"].each do |content|
        File.binwrite(@path, content)

        assert_equal 0, HighScore.new(path: @path).best, content.inspect
      end
    end

    def test_high_score_path_is_a_directory_is_zero
      assert_equal 0, HighScore.new(path: @dir).best
    end

    def test_save_creates_directory_and_leaves_no_temp_file
      nested = File.join(@dir, 'a', 'b', 'hs.json')
      HighScore.new(path: nested).record(4)

      assert_equal 4, HighScore.new(path: nested).best
      assert_equal ['hs.json'], Dir.children(File.dirname(nested))
    end

    def test_unwritable_save_does_not_crash
      blocker = File.join(@dir, 'file')
      File.write(blocker, 'x')
      hs = HighScore.new(path: File.join(blocker, 'hs.json'))

      assert_output(nil, /Could not save/) { assert_equal 3, hs.record(3) }
    end
  end
end

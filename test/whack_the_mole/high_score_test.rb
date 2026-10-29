# frozen_string_literal: true

require 'tmpdir'
require_relative '../test_helper'

module WhackTheMole
  class HighScoreTest < Minitest::Test
    def setup
      @dir = Dir.mktmpdir
      @path = File.join(@dir, 'nested', 'highscore.json')
    end

    def teardown
      FileUtils.remove_entry(@dir)
    end

    def test_missing_file_is_zero
      assert_equal 0, HighScore.new(path: @path).best
    end

    def test_bad_files_are_zero
      FileUtils.mkdir_p(File.dirname(@path))
      ['not json', '[]', '{"best":"x"}', '5', ''].each do |content|
        File.write(@path, content)

        assert_equal 0, HighScore.new(path: @path).best, content
      end
    end

    def test_record_saves_only_higher_scores
      high_score = HighScore.new(path: @path)

      assert_equal 5, high_score.record(5)
      assert_equal 5, high_score.record(3)
      assert_equal 5, HighScore.new(path: @path).best
      refute_path_exists "#{@path}.tmp"
    end

    def test_negative_score_does_not_create_a_file
      HighScore.new(path: @path).record(-2)

      refute_path_exists @path
    end
  end
end

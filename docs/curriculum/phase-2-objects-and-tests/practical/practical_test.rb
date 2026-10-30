# frozen_string_literal: true

require 'fileutils'
require 'minitest/autorun'
require 'tmpdir'
require_relative 'practical'

class PracticalTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @path = File.join(@dir, 'nested', 'history.json')
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def test_result_total_and_accuracy
    result = Result.new(hits: 3, misses: 1)

    assert_equal 2, result.total
    assert_in_delta 0.75, result.accuracy
  end

  def test_result_accuracy_with_no_clicks_is_zero
    assert_in_delta 0.0, Result.new(hits: 0, misses: 0).accuracy
  end

  def test_result_is_an_immutable_value
    result = Result.new(hits: 1, misses: 2)

    assert_equal Result.new(hits: 1, misses: 2), result
    assert_equal Result.new(hits: 4, misses: 2), result.with(hits: 4)
    refute_respond_to result, :hits=
  end

  def test_default_path_is_a_class_method
    assert ScoreHistory.default_path.end_with?(File.join('WhackTheMole', 'history.json'))
  end

  def test_public_interface_is_small
    assert_equal %i[add average scores], ScoreHistory.public_instance_methods(false).sort
  end

  def test_missing_file_means_no_scores
    assert_empty ScoreHistory.new(path: @path).scores
  end

  def test_corrupt_files_mean_no_scores
    FileUtils.mkdir_p(File.dirname(@path))
    ['nope', '', '[1]', '{}', '{"scores":"1"}', '{"scores":[1,"x"]}', '{"scores":[2.5]}'].each do |content|
      File.write(@path, content)

      assert_empty ScoreHistory.new(path: @path).scores, content
    end
  end

  def test_add_keeps_newest_first_up_to_the_limit
    history = ScoreHistory.new(path: @path, limit: 3)
    [1, 2, 3, 4].each { |score| history.add(score) }

    assert_equal [4, 3, 2], history.scores
  end

  def test_default_limit_is_five
    history = ScoreHistory.new(path: @path)
    (1..7).each { |score| history.add(score) }

    assert_equal [7, 6, 5, 4, 3], history.scores
  end

  def test_scores_persist_with_an_atomic_write
    ScoreHistory.new(path: @path).add(-2)
    ScoreHistory.new(path: @path).add(9)

    assert_equal [9, -2], ScoreHistory.new(path: @path).scores
    refute_path_exists "#{@path}.tmp"
  end

  def test_add_rejects_non_integers
    history = ScoreHistory.new(path: @path)

    assert_raises(ArgumentError) { history.add('7') }
    assert_raises(ArgumentError) { history.add(2.5) }
    assert_empty history.scores
  end

  def test_average
    history = ScoreHistory.new(path: @path)

    assert_nil history.average
    history.add(4)
    history.add(1)

    assert_in_delta 2.5, history.average
  end

  def test_callers_cannot_change_the_stored_scores
    history = ScoreHistory.new(path: @path)
    history.add(1)
    scores = history.scores
    scores.clear unless scores.frozen?

    assert_equal [1], history.scores
  end

  def test_failed_save_warns_and_keeps_scores_in_memory
    blocker = File.join(@dir, 'blocker')
    File.write(blocker, 'a file where a folder should be')
    history = ScoreHistory.new(path: File.join(blocker, 'history.json'))

    assert_output(nil, /Could not save/) { history.add(5) }
    assert_equal [5], history.scores
  end
end

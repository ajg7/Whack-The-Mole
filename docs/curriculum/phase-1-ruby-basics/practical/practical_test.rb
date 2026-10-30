# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'practical'

class PracticalTest < Minitest::Test
  def test_clock_label_rounds_seconds_up
    assert_equal '1:00', clock_label(60_000)
    assert_equal '1:00', clock_label(59_001)
    assert_equal '0:59', clock_label(59_000)
    assert_equal '0:01', clock_label(1)
    assert_equal '0:00', clock_label(0)
    assert_equal '2:05', clock_label(125_000)
  end

  def test_up_time_interpolates_and_clamps
    assert_equal 1200, up_time(0)
    assert_equal 1050, up_time(0.25)
    assert_equal 900, up_time(0.5)
    assert_equal 600, up_time(1)
    assert_equal 600, up_time(1.5)
    assert_equal 1200, up_time(-1)
    assert_equal 150, up_time(0.5, start: 100, finish: 200)
  end

  def test_grid_rows_numbers_holes_row_by_row
    assert_equal [[1, 2, 3], [4, 5, 6]], grid_rows(cols: 3, rows: 2)
    assert_equal [[1], [2]], grid_rows(cols: 1, rows: 2)
  end

  def test_pick_counts_is_repeatable_and_complete
    counts = pick_counts(%i[a b c], 300, seed: 7)

    assert_equal counts, pick_counts(%i[a b c], 300, seed: 7)
    assert_equal 300, counts.values.sum
    assert_empty counts.keys - %i[a b c]
    assert_instance_of Hash, counts
  end

  def test_phase_for_follows_the_mole_life_cycle
    assert_equal :rising, phase_for(0, 600)
    assert_equal :rising, phase_for(239, 600)
    assert_equal :up, phase_for(240, 600)
    assert_equal :up, phase_for(839, 600)
    assert_equal :hiding, phase_for(840, 600)
    assert_equal :gone, phase_for(1080, 600)
  end

  def test_first_inside_finds_the_first_point_in_the_box
    points = [[0, 0], [15, 15], [12, 11], [40, 40]]

    assert_equal [15, 15], first_inside(points, left: 10, top: 10, width: 10, height: 10)
    assert_equal [20, 20], first_inside([[20, 20]], left: 10, top: 10, width: 10, height: 10)
    assert_nil first_inside(points, left: 100, top: 100, width: 5, height: 5)
  end

  def test_safe_best_only_trusts_a_positive_integer
    assert_equal 12, safe_best({ 'best' => 12 })
    assert_equal 0, safe_best({ best: 12 })
    assert_equal 0, safe_best({ 'best' => '12' })
    assert_equal 0, safe_best({ 'best' => -3 })
    assert_equal 0, safe_best([12])
    assert_equal 0, safe_best(nil)
  end

  def test_fallback_returns_the_block_value_or_the_default
    assert_equal 5, fallback(0) { 5 }
    assert_equal :none, fallback(:none) { raise 'missing file' }
    assert_raises(ZeroDivisionError) { fallback(0) { 1 / 0 } }
  end

  def test_remove_expired_changes_the_array_in_place
    ages = [100, 900, 300, 1200]
    result = remove_expired!(ages, 800)

    assert_equal [100, 300], ages
    assert_same ages, result
  end

  def test_shout_does_not_modify_its_argument
    text = 'whack'

    assert_equal 'WHACK!', shout(text)
    assert_equal 'whack', text
  end
end

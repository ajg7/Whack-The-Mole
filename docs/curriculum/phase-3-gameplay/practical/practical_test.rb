# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'practical'

class PracticalTest < Minitest::Test
  def setup
    @shake = ScreenShake.new(started_at: 1000, duration_ms: 200, magnitude: 8)
  end

  def test_rect_contains_includes_its_edges
    rect = Rect.new(x: 10, y: 20, w: 30, h: 40)

    assert rect.contains?(10, 20)
    assert rect.contains?(40, 60)
    refute rect.contains?(41, 60)
    refute rect.contains?(10, 19)
  end

  def test_rect_overlaps_only_with_shared_area
    rect = Rect.new(x: 0, y: 0, w: 10, h: 10)

    assert rect.overlaps?(Rect.new(x: 5, y: 5, w: 10, h: 10))
    assert rect.overlaps?(Rect.new(x: 2, y: 2, w: 2, h: 2))
    refute rect.overlaps?(Rect.new(x: 10, y: 0, w: 5, h: 5))
    refute rect.overlaps?(Rect.new(x: 0, y: 20, w: 5, h: 5))
  end

  def test_rect_is_a_value
    assert_equal Rect.new(x: 1, y: 2, w: 3, h: 4), Rect.new(x: 1, y: 2, w: 3, h: 4)
  end

  def test_lerp_and_ease_out
    assert_in_delta 900.0, lerp(1200, 600, 0.5)
    assert_in_delta 0.0, ease_out(0)
    assert_in_delta 0.75, ease_out(0.5)
    assert_in_delta 1.0, ease_out(1)
    assert_in_delta 1.0, ease_out(2)
    assert_in_delta 0.0, ease_out(-1)
  end

  def test_frame_at_plays_once_and_holds_the_last_frame
    assert_equal([0, 0, 1, 2, 2], [0, 99, 100, 250, 999].map { |ms| frame_at(ms, frame_ms: 100, frames: 3) })
    assert_equal 0, frame_at(-50, frame_ms: 100, frames: 3)
  end

  def test_frame_at_can_repeat
    frames = [0, 100, 200, 300, 450].map { |ms| frame_at(ms, frame_ms: 100, frames: 3, repeat: true) }

    assert_equal [0, 1, 2, 0, 1], frames
  end

  def test_flow_follows_the_screen_state_machine
    flow = Flow.new

    assert_equal :title, flow.state
    assert_equal(%i[countdown countdown playing game_over countdown],
                 %i[click click countdown_done time_up click].map { |event| flow.fire(event) })
  end

  def test_flow_ignores_events_that_do_not_apply
    flow = Flow.new

    assert_equal :title, flow.fire(:time_up)
    assert_equal :title, flow.fire(:explode)
  end

  def test_flow_reports_whether_the_last_event_changed_state
    flow = Flow.new
    flow.fire(:click)

    assert_predicate flow, :changed?
    flow.fire(:click)

    refute_predicate flow, :changed?
  end

  def test_shake_is_active_only_during_its_duration
    refute @shake.active?(999)
    assert @shake.active?(1000)
    assert @shake.active?(1199)
    refute @shake.active?(1200)
  end

  def test_shake_offsets_are_whole_pixels_up_to_the_magnitude
    random = Random.new(3)
    start = Array.new(50) { @shake.offset(1000, random:) }.flatten

    assert(start.all? { |d| d.is_a?(Integer) && d.between?(-8, 8) })
    assert(start.any? { |d| d.abs > 4 })
  end

  def test_shake_offsets_shrink_then_stop
    random = Random.new(3)
    halfway = Array.new(50) { @shake.offset(1100, random:) }.flatten

    assert(halfway.all? { |d| d.between?(-4, 4) })
    assert_equal [0, 0], @shake.offset(1200, random:)
    assert_equal [0, 0], @shake.offset(900, random:)
  end

  def test_shake_is_repeatable_with_the_same_seed
    assert_equal @shake.offset(1050, random: Random.new(9)), @shake.offset(1050, random: Random.new(9))
  end
end

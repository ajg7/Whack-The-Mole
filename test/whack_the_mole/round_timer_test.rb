# frozen_string_literal: true

require_relative '../test_helper'

module WhackTheMole
  class RoundTimerTest < Minitest::Test
    def setup
      @timer = RoundTimer.new(started_at: 1000, duration_ms: 60_000)
    end

    def test_clock_label_counts_down
      assert_equal '1:00', @timer.clock_label(1000)
      assert_equal '1:00', @timer.clock_label(1001)
      assert_equal '0:59', @timer.clock_label(2000)
      assert_equal '0:00', @timer.clock_label(61_000)
      assert_equal '0:00', @timer.clock_label(99_000)
    end

    def test_label_is_full_before_start
      assert_equal '1:00', @timer.clock_label(0)
    end

    def test_expired_exactly_at_duration
      refute @timer.expired?(60_999)
      assert @timer.expired?(61_000)
    end

    def test_elapsed_fraction
      assert_in_delta 0.0, @timer.elapsed_fraction(1000)
      assert_in_delta 0.5, @timer.elapsed_fraction(31_000)
      assert_in_delta 1.0, @timer.elapsed_fraction(70_000)
    end

    def test_seconds_left_for_countdown
      countdown = RoundTimer.new(started_at: 0, duration_ms: 3000)

      assert_equal([3, 3, 2, 1], [0, 999, 1000, 2000].map { |now| countdown.seconds_left(now) })
    end
  end
end

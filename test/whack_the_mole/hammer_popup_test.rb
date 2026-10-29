# frozen_string_literal: true

require_relative '../test_helper'

module WhackTheMole
  class HammerPopupTest < Minitest::Test
    def test_hammer_swings_then_rests
      hammer = Hammer.new

      assert_equal 0, hammer.frame(0)
      hammer.swing(100)

      assert_equal([0, 1, 2, 0], [100, 150, 200, 250].map { |now| hammer.frame(now) })
    end

    def test_hit_point_applies_offset
      dx, dy = Config::HAMMER_HEAD_OFFSET

      assert_equal [10 + dx, 20 + dy], Hammer.hit_point(10, 20)
    end

    def test_popup_rises_fades_and_expires
      popup = Popup.new(x: 0, y: 0, started_at: 1000)

      assert_equal 255, popup.alpha(1000)
      assert_in_delta(-Config::POPUP_RISE, popup.offset(1000 + Config::POPUP_MS))
      refute popup.expired?(1000 + Config::POPUP_MS - 1)
      assert popup.expired?(1000 + Config::POPUP_MS)
    end
  end
end

# frozen_string_literal: true

require_relative '../test_helper'

module WhackTheMole
  class MoleTest < Minitest::Test
    def setup
      @mole = Mole.new(hole: Hole.new(x: 100, y: 200), spawned_at: 1000, up_ms: 1000)
    end

    def test_frames_follow_the_life_cycle
      times = [1000, 1080, 1160, 1240, 2239, 2240, 2320, 2400, 2480]

      assert_equal([0, 1, 2, 3, 3, 2, 1, 0, 0], times.map { |now| @mole.frame(now) })
    end

    def test_phases
      assert_equal(%i[rising up hiding gone], [1000, 1240, 2240, 2480].map { |now| @mole.phase(now) })
    end

    def test_whacked_mole_drops_then_is_gone
      @mole.whack(1100)

      assert_equal :dropping, @mole.phase(1119)
      assert_equal([2, 1, 0], [1100, 1140, 1180].map { |now| @mole.frame(now) })
      assert_predicate @mole, :whacked?
      assert @mole.gone?(1220)
    end

    def test_hittable_only_once_and_only_while_up
      assert @mole.hittable?(1000)
      assert @mole.hittable?(1500)
      refute @mole.hittable?(2300)
      @mole.whack(1500)

      refute @mole.hittable?(1501)
    end

    def test_contains_uses_the_drawn_sprite_rect
      assert @mole.contains?(100, 150)
      refute @mole.contains?(100, 300)
      refute @mole.contains?(10, 150)
    end
  end
end

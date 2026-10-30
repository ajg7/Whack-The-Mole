# frozen_string_literal: true

require 'test_helper'

class ScoreTest < ActiveSupport::TestCase
  def build(**overrides)
    Score.new({ player_name: 'AJ', points: 2, hits: 3, misses: 1 }.merge(overrides))
  end

  test 'a consistent score is valid' do
    assert_predicate build, :valid?
  end

  test 'player name is required and at most 20 characters' do
    assert_not build(player_name: '').valid?
    assert_not build(player_name: nil).valid?
    assert_predicate build(player_name: 'a' * 20), :valid?
    assert_not build(player_name: 'a' * 21).valid?
  end

  test 'hits and misses are whole numbers and not negative' do
    assert_not build(hits: -1, misses: 0, points: -1).valid?
    assert_not build(misses: 'x').valid?
    assert_not build(hits: 2.5, points: 1.5).valid?
  end

  test 'points must equal hits minus misses' do
    score = build(points: 9)

    assert_not score.valid?
    assert_includes score.errors[:points], 'must equal hits minus misses'
  end

  test 'negative totals are allowed' do
    assert_predicate build(points: -3, hits: 0, misses: 3), :valid?
  end

  test 'top orders by points, breaks ties by earliest, and keeps ten' do
    oldest = Score.create!(player_name: 'Oldest', points: 20, hits: 20, misses: 0, created_at: 4.days.ago)
    10.times { |i| Score.create!(player_name: "P#{i}", points: 2, hits: 3, misses: 1) }

    assert_equal 10, Score.top.size
    assert_equal [oldest, scores(:ace), scores(:early), scores(:late)], Score.top.first(4)
  end

  test 'since keeps only scores created after the given time' do
    recent = Score.since(36.hours.ago)

    assert_includes recent, scores(:late)
    assert_includes recent, scores(:rookie)
    assert_not_includes recent, scores(:early)
  end
end

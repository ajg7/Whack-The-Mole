# frozen_string_literal: true

class Score < ApplicationRecord
  validates :player_name, presence: true, length: { maximum: 20 }
  validates :points, numericality: { only_integer: true }
  validates :hits, :misses, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :points_match_hits_and_misses

  scope :top, -> { order(points: :desc, created_at: :asc).limit(10) }
  scope :since, ->(time) { where(created_at: time..) }

  private

  def points_match_hits_and_misses
    return if points.nil? || hits.nil? || misses.nil?

    errors.add(:points, 'must equal hits minus misses') unless points == hits - misses
  end
end

# frozen_string_literal: true

require 'fileutils'
require 'json'

Result = Data.define(:hits, :misses) do
  def total
    hits - misses
  end

  def accuracy
    clicks = hits + misses
    clicks.zero? ? 0.0 : hits.to_f / clicks
  end
end

class ScoreHistory
  def self.default_path
    File.join(ENV.fetch('APPDATA') { Dir.home }, 'WhackTheMole', 'history.json')
  end

  def initialize(path: self.class.default_path, limit: 5)
    @path = path
    @limit = limit
    @scores = load
  end

  def scores
    @scores.dup
  end

  def add(score)
    raise ArgumentError, 'score must be an Integer' unless score.is_a?(Integer)

    @scores = [score, *@scores].first(@limit)
    save
  end

  def average
    return if @scores.empty?

    @scores.sum.to_f / @scores.size
  end

  private

  def load
    data = JSON.parse(File.read(@path))
    scores = data.is_a?(Hash) ? data['scores'] : nil
    scores.is_a?(Array) && scores.all?(Integer) ? scores.first(@limit) : []
  rescue JSON::ParserError, SystemCallError
    []
  end

  def save
    FileUtils.mkdir_p(File.dirname(@path))
    temp_path = "#{@path}.tmp"
    File.write(temp_path, JSON.generate(scores: @scores))
    File.rename(temp_path, @path)
  rescue SystemCallError => e
    warn "Could not save scores: #{e.message}"
  end
end

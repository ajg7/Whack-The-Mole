# frozen_string_literal: true

require 'fileutils'
require 'json'

module WhackTheMole
  class HighScore
    def self.default_path
      File.join(ENV.fetch('APPDATA') { Dir.home }, 'WhackTheMole', 'highscore.json')
    end

    attr_reader :best

    def initialize(path: self.class.default_path)
      @path = path
      @best = load
    end

    def record(score)
      if score > best
        @best = score
        save
      end
      best
    end

    private

    def load
      data = JSON.parse(File.read(@path))
      data.is_a?(Hash) && data['best'].is_a?(Integer) && data['best'].positive? ? data['best'] : 0
    rescue JSON::ParserError, SystemCallError
      0
    end

    def save
      FileUtils.mkdir_p(File.dirname(@path))
      temp_path = "#{@path}.tmp"
      File.write(temp_path, JSON.generate(best: best))
      File.rename(temp_path, @path)
    rescue SystemCallError => e
      warn "Could not save high score: #{e.message}"
    end
  end
end

# frozen_string_literal: true

require 'gosu'
require_relative '../whack_the_mole'

module WhackTheMole
  class Window < Gosu::Window
    HOLE_SEGMENTS = 32

    def initialize
      super(Config::WIDTH, Config::HEIGHT)
      self.caption = 'Whack-The-Mole'
      @game = Game.new(random: Random.new, high_score: HighScore.new)
      @moles = load_tiles('mole-sheet.png')
      @hammers = load_tiles('hammer-sheet.png')
      @font = Gosu::Font.new(32)
      @song = load_audio { Gosu::Song.new(asset('dcuttermusic-whack-a-mole-178509.mp3')) }
      @thud = load_audio { Gosu::Sample.new(asset('freesound_community-thud2-97615.mp3')) }
      @previous_state = @game.state
    end

    def needs_cursor?
      false
    end

    def update
      @game.update(Gosu.milliseconds)
      sync_music
    end

    def button_down(id)
      case id
      when Gosu::MS_LEFT then play_thud(@game.click(mouse_x, mouse_y, now: Gosu.milliseconds))
      when Gosu::KB_R then restart if @game.state == :game_over
      else super
      end
    end

    def draw
      now = Gosu.milliseconds
      Gosu.draw_rect(0, 0, Config::WIDTH, Config::HEIGHT, Config::GRASS_COLOR)
      draw_holes
      draw_moles(now)
      draw_popups(now)
      draw_hud(now)
      draw_hammer(now)
    end

    private

    def asset(name)
      File.join(Config::ASSETS_DIR, name)
    end

    def restart
      now = Gosu.milliseconds
      @game.hammer.swing(now)
      @game.start(now)
    end

    def load_tiles(name)
      Gosu::Image.load_tiles(asset(name), Config::SPRITE_SIZE, Config::SPRITE_SIZE, retro: true)
    rescue RuntimeError
      abort "Could not load image: #{asset(name)}"
    end

    def load_audio
      yield
    rescue RuntimeError
      nil
    end

    def draw_hole(hole)
      color = Config::HOLE_COLOR
      radius_x = Config::HOLE_WIDTH / 2.0
      radius_y = Config::HOLE_HEIGHT / 2.0
      points = (0..HOLE_SEGMENTS).map do |i|
        angle = 2 * Math::PI * i / HOLE_SEGMENTS
        [hole.x + (radius_x * Math.cos(angle)), hole.y + (radius_y * Math.sin(angle))]
      end
      points.each_cons(2) do |(x1, y1), (x2, y2)|
        Gosu.draw_triangle(hole.x, hole.y, color, x1, y1, color, x2, y2, color, 1)
      end
    end

    def sync_music
      return if @game.state == @previous_state

      @song&.play(true) if @game.state == :countdown
      @song&.stop if @game.state == :game_over
      @previous_state = @game.state
    end

    def play_thud(result)
      @thud&.play(1.0, Config::MISS_SPEED) if result == :miss
      @thud&.play(1.0, 1.0) if result == :hit
    end

    def draw_holes
      Hole.grid.each { |hole| draw_hole(hole) }
    end

    def draw_moles(now)
      @game.moles.each do |mole|
        @moles[mole.frame(now)].draw(mole.left, mole.top, 2, Config::SCALE, Config::SCALE)
      end
    end

    def draw_popups(now)
      @game.popups.each do |popup|
        color = (popup.alpha(now) << 24) | (Config::TEXT_COLOR & 0xffffff)
        @font.draw_text_rel('+1', popup.x, popup.y + popup.offset(now), 4, 0.5, 0.5, 1, 1, color)
      end
    end

    def draw_hud(now)
      case @game.state
      when :title then draw_center('Click to start')
      when :countdown then draw_countdown(now)
      when :playing then draw_status(now)
      when :game_over then draw_game_over
      end
    end

    def draw_countdown(now)
      draw_status(now)
      draw_center(@game.countdown_number(now).to_s)
    end

    def draw_status(now)
      @font.draw_text(@game.clock_label(now), 16, 16, 5, 1, 1, Config::TEXT_COLOR)
      @font.draw_text_rel("Score: #{@game.score.total}", Config::WIDTH - 16, 16, 5, 1.0, 0.0)
    end

    def draw_game_over
      score = @game.score
      lines = ['Game over', "Score: #{score.total}", "Hits: #{score.hits}   Misses: #{score.misses}",
               "Best: #{@game.best}", 'Click or press R to play again']
      lines.each_with_index { |line, i| draw_center(line, (Config::HEIGHT / 2) + ((i - 2) * 48)) }
    end

    def draw_center(text, y = Config::HEIGHT / 2)
      @font.draw_text_rel(text, Config::WIDTH / 2, y, 5, 0.5, 0.5, 1, 1, Config::TEXT_COLOR)
    end

    def draw_hammer(now)
      half = Config::DRAWN_SIZE / 2
      @hammers[@game.hammer.frame(now)].draw(mouse_x - half, mouse_y - half, 10, Config::SCALE, Config::SCALE)
    end
  end
end

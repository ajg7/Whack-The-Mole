# frozen_string_literal: true

module WhackTheMole
  class Game
    attr_reader :state, :score, :moles, :popups, :hammer, :best

    def initialize(random:, high_score:)
      @random = random
      @high_score = high_score
      @best = high_score.best
      @hammer = Hammer.new
      @state = :title
      @score = Score.new
      @moles = []
      @popups = []
    end

    def update(now)
      case state
      when :countdown then start_round(now) if @countdown.expired?(now)
      when :playing then update_round(now)
      end
    end

    def click(x, y, now:)
      hammer.swing(now)
      case state
      when :title, :game_over then start(now)
      when :playing then whack_at(*Hammer.hit_point(x, y), now)
      end
    end

    def start(now)
      @state = :countdown
      @score = Score.new
      @moles = []
      @popups = []
      @countdown = RoundTimer.new(started_at: now, duration_ms: Config::COUNTDOWN_MS)
      @round = RoundTimer.new(started_at: now + Config::COUNTDOWN_MS, duration_ms: Config::ROUND_MS)
    end

    def clock_label(now)
      @round.clock_label(now)
    end

    def countdown_number(now)
      @countdown.seconds_left(now)
    end

    private

    def start_round(now)
      @state = :playing
      @next_spawn_at = now
      update_round(now)
    end

    def update_round(now)
      return finish_round if @round.expired?(now)

      moles.reject! { |mole| mole.gone?(now) }
      popups.reject! { |popup| popup.expired?(now) }
      spawn_mole(now) if moles.size < Config::MAX_MOLES && now >= @next_spawn_at
    end

    def finish_round
      @state = :game_over
      @moles = []
      @popups = []
      @best = @high_score.record(score.total)
    end

    def spawn_mole(now)
      free_holes = Hole.grid - moles.map(&:hole)
      up_ms = Config::UP_MS_START + ((Config::UP_MS_END - Config::UP_MS_START) * @round.elapsed_fraction(now))
      moles << Mole.new(hole: free_holes.sample(random: @random), spawned_at: now, up_ms: up_ms.round)
      @next_spawn_at = now + Config::SPAWN_INTERVAL_MS
    end

    def whack_at(x, y, now)
      mole = moles.find { |candidate| candidate.hittable?(now) && candidate.contains?(x, y) }
      if mole
        mole.whack(now)
        score.hit!
        popups << Popup.new(x: mole.hole.x, y: mole.top, started_at: now)
        :hit
      else
        score.miss!
        :miss
      end
    end
  end
end

# frozen_string_literal: true

Rect = Data.define(:x, :y, :w, :h) do
  def right = x + w
  def bottom = y + h

  def contains?(point_x, point_y)
    point_x.between?(x, right) && point_y.between?(y, bottom)
  end

  def overlaps?(other)
    x < other.right && other.x < right && y < other.bottom && other.y < bottom
  end
end

def lerp(start, finish, fraction)
  start + ((finish - start) * fraction)
end

def ease_out(fraction)
  1 - ((1 - fraction.clamp(0.0, 1.0))**2)
end

def frame_at(elapsed, frame_ms:, frames:, repeat: false)
  step = [elapsed, 0].max / frame_ms
  repeat ? step % frames : [step, frames - 1].min
end

class Flow
  TRANSITIONS = {
    title: { click: :countdown },
    countdown: { countdown_done: :playing },
    playing: { time_up: :game_over },
    game_over: { click: :countdown }
  }.freeze

  attr_reader :state

  def initialize
    @state = :title
    @changed = false
  end

  def fire(event)
    next_state = TRANSITIONS[state].fetch(event, state)
    @changed = next_state != state
    @state = next_state
  end

  def changed?
    @changed
  end
end

ScreenShake = Data.define(:started_at, :duration_ms, :magnitude) do
  def active?(now)
    now >= started_at && now < started_at + duration_ms
  end

  def offset(now, random:)
    return [0, 0] unless active?(now)

    strength = (magnitude * (1.0 - ((now - started_at).to_f / duration_ms))).round
    [random.rand(-strength..strength), random.rand(-strength..strength)]
  end
end

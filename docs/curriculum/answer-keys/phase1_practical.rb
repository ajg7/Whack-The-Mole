# frozen_string_literal: true

def clock_label(milliseconds)
  minutes, seconds = (milliseconds / 1000.0).ceil.divmod(60)
  format('%<minutes>d:%<seconds>02d', minutes:, seconds:)
end

def up_time(fraction, start: 1200, finish: 600)
  (start + ((finish - start) * fraction.clamp(0, 1))).round
end

def grid_rows(cols:, rows:)
  (1..(cols * rows)).each_slice(cols).to_a
end

def pick_counts(items, picks, seed:)
  random = Random.new(seed)
  counts = Hash.new(0)
  picks.times { counts[items.sample(random:)] += 1 }
  counts
end

def phase_for(age, up_ms)
  transition = 240
  if age < transition then :rising
  elsif age < transition + up_ms then :up
  elsif age < (2 * transition) + up_ms then :hiding
  else :gone
  end
end

def first_inside(points, left:, top:, width:, height:)
  points.find { |x, y| x.between?(left, left + width) && y.between?(top, top + height) }
end

def safe_best(data)
  data.is_a?(Hash) && data['best'].is_a?(Integer) && data['best'].positive? ? data['best'] : 0
end

def fallback(default)
  yield
rescue RuntimeError
  default
end

def remove_expired!(ages, limit)
  ages.reject! { |age| age >= limit }
  ages
end

def shout(text)
  "#{text.upcase}!"
end

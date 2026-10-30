# Phase 1 summative assessment: Ruby basics

Pass all three parts to unlock phase 2. See [the README](../README.md#passing-a-gate) for the rules.

All `Config` values are the ones in `lib/whack_the_mole/config.rb` as committed.

---

## Part A: written (closed-book, 47 points, pass at 38)

Write your answers in a file `practice/phase1/answers.md`. Don't run code for this part; predicting is the skill being tested.

### Q1 (1 pt)
Which statement about `Gemfile` and `Gemfile.lock` is true?

a) You edit `Gemfile.lock` by hand to add a gem.
b) `Gemfile` lists the gems and allowed version ranges; `Gemfile.lock` records the exact versions Bundler chose, and both are committed.
c) `Gemfile.lock` is generated on every run and should be in `.gitignore`.
d) `Gemfile` is only needed for tests.

_Covers: R1.2_

### Q2 (2 pts)
(a) Why does this project run `bundle exec rake test` rather than `rake test`? (b) What does `bundle exec rake` with no task name do in this repo, and why?

_Covers: R1.1, R1.2_

### Q3 (1 pt)
Which value should be a Symbol rather than a String?

a) The player's name typed on a title screen
b) The text `"Game over"` drawn on the screen
c) The current game state, one of four values the programmer chose
d) The path to the high-score file

_Covers: R1.3_

### Q4 (4 pts)
Predict each result.

```ruby
59_500 / 1000
(59_500 / 1000.0).ceil
7.0 / 2
-7 / 2
```

_Covers: R1.4_

### Q5 (3 pts)
```ruby
timer = WhackTheMole::RoundTimer.new(started_at: 1000, duration_ms: 60_000)
timer.remaining_ms(500)
timer.seconds_left(60_999)
timer.clock_label(1000)
```
Predict each of the three results and explain the first one in a sentence.

_Covers: R1.4, R1.6_

### Q6 (3 pts)
(a) In `Game#spawn_mole`, classify each of `free_holes`, `@random` and `SPAWN_INTERVAL_MS` as a local variable, an instance variable or a constant. (b) What happens if code runs `Config::HAMMER_HEAD_OFFSET << 5`, and why?

_Covers: R1.5_

### Q7 (2 pts)
With `total = 3`, what does each line print?

```ruby
puts 'Score: #{total}'
puts format('%<m>d:%<s>02d', m: 0, s: 7)
```

_Covers: R1.6_

### Q8 (2 pts)
What does `Game#update(now)` do when `state` is `:title`? Explain using how `case`/`when` behaves.

_Covers: R1.7_

### Q9 (3 pts)
A mole is created with `spawned_at: 0, up_ms: 600`. `Mole::TRANSITION_MS` is 240. Give `phase(now)` for `now` = 239, 240, 839, 840, 1079, 1080. (Half a point each.)

_Covers: R1.7_

### Q10 (2 pts)
Which of these are truthy in Ruby? `0`, `""`, `nil`, `[]`, `false`, `:false`

_Covers: R1.8_

### Q11 (2 pts)
`Window#sync_music` calls `@song&.play(true)`. What happens when the music file failed to load? Why is `&.` used here instead of an `if`?

_Covers: R1.8_

### Q12 (2 pts)
`Game#initialize` is `def initialize(random:, high_score:)`. For each call, say whether it works or raises, and why.

```ruby
Game.new(Random.new, hs)
Game.new(high_score: hs, random: Random.new)
Game.new(random: Random.new)
```

_Covers: R1.9_

### Q13 (1 pt)
You're adding a method to `RoundTimer` that returns whether more than half the round has passed. Which name follows Ruby conventions?

a) `get_past_half`  b) `past_half?`  c) `pastHalf`  d) `past_half!`

_Covers: R1.10_

### Q14 (2 pts)
(a) What does `Hammer.hit_point(100, 50)` return? (b) In `whack_at(*Hammer.hit_point(100, 50), 900)`, what are `x`, `y` and `now` inside `whack_at`?

_Covers: R1.11_

### Q15 (2 pts)
`Hole.grid(cols: 2, rows: 2)`: how many holes does it return, and what are the `x` and `y` of the first two, in order? Show your arithmetic. (`GRID_LEFT` is computed from the default 3 columns.)

_Covers: R1.12, R1.13_

### Q16 (2 pts)
```ruby
free = [1, 2, 3, 4, 5] - [2, 5]
free.size
```
(a) What is `free.size`? (b) Will `free.sample(random: Random.new(7))` give the same element every time the program runs? Why does the game use this instead of plain `sample`?

_Covers: R1.12_

### Q17 (2 pts)
Predict: `(0...3).to_a`, `(0..3).to_a`, `5.between?(5, 9)`, `9.5.between?(5, 9)`. (Half a point each.)

_Covers: R1.13_

### Q18 (2 pts)
```ruby
require 'json'
data = JSON.parse('{"best": 9}')
data[:best]
data['best']
```
Predict both lookups and explain the difference.

_Covers: R1.14_

### Q19 (2 pts)
Predict: `[4, 9, 2, 7].select(&:odd?).map { |n| n * 2 }` and `[4, 9, 2, 7].find { |n| n > 10 }`.

_Covers: R1.15_

### Q20 (2 pts)
```ruby
def safely
  yield
rescue RuntimeError
  :fallback
end

safely { 5 }
safely { raise 'no file' }
```
Predict both results. Name the method in `window.rb` that uses this pattern.

_Covers: R1.16_

### Q21 (2 pts)
```ruby
a = [1, 2, 3, 4]
b = a.reject(&:even?)
a.reject!(&:odd?)
```
What are `a` and `b` afterwards? Which line changed `a`?

_Covers: R1.15, R1.17_

### Q22 (1 pt)
Why does every file in `lib/` wrap its code in `module WhackTheMole`?

_Covers: R1.18_

### Q23 (2 pts)
(a) Why does `high_score.rb` use `require 'json'` but `lib/whack_the_mole.rb` uses `require_relative 'whack_the_mole/config'`? (b) Why is `ASSETS_DIR` built with `File.expand_path(..., __dir__)` instead of the plain string `'assets'`?

_Covers: R1.19_

---

## Part B: practical (open-book, autograded)

1. Copy [practical/practical_test.rb](practical/practical_test.rb) to `practice/phase1/practical_test.rb`.
2. Create `practice/phase1/practical.rb` and write the ten methods it tests. Read the tests: they are the specification.
3. Pass when `ruby practice/phase1/practical_test.rb` reports 0 failures and 0 errors and `bundle exec rubocop practice/phase1` reports no offenses.

Rules: top-level methods only (no classes); don't edit the test file; don't require the game's code.

| Method | Objectives it exercises |
|---|---|
| `clock_label(milliseconds)` | R1.4, R1.6 |
| `up_time(fraction, start: 1200, finish: 600)` | R1.4, R1.9 |
| `grid_rows(cols:, rows:)` | R1.12, R1.13, R1.15 |
| `pick_counts(items, picks, seed:)` | R1.12, R1.14 |
| `phase_for(age, up_ms)` | R1.3, R1.7 |
| `first_inside(points, left:, top:, width:, height:)` | R1.11, R1.13, R1.15 |
| `safe_best(data)` | R1.8, R1.14 |
| `fallback(default) { ... }` | R1.16 |
| `remove_expired!(ages, limit)` | R1.10, R1.17 |
| `shout(text)` | R1.5, R1.6 |

---

## Part C: project (the Field Report)

Graded against `scripts/field_report.rb` as described at the end of [the lessons](lessons.md#phase-1-project-the-field-report). Every row must be **Meets** or **Exceeds**.

| Criterion | Below | Meets | Exceeds |
|---|---|---|---|
| Correctness | A section is missing or a number is wrong | All four sections print, and the numbers match the game's config and formulas | Output adapts if you change `GRID_COLS`/`GRID_ROWS` in config, with no edit to the script |
| Determinism | Same seed prints different counts | Same seed, same counts; different seed usually different counts; counts sum to 1,000 | Seed is validated (non-numeric `ARGV` falls back to 42 with a message) |
| Idiomatic Ruby | Index-counting loops (`while i < n`), repeated code | Uses `each`/`map`/`each_slice`/`each_with_index`, a Hash for counts, interpolation or `format` for output | Each section is its own small method with a clear name |
| Style | RuboCop offenses | `bundle exec rubocop scripts/field_report.rb` is clean, frozen string literal present | No comments needed to understand it |
| Explanation | Can't explain a line | Ask Claude to pick three lines at random and quiz you; you explain each correctly without looking at the lessons | You can also explain how you'd test it |

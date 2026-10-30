# Phase 2 summative assessment: objects and tests

Pass all three parts to unlock phase 3. See [the README](../README.md#passing-a-gate) for the rules.

---

## Part A: written (closed-book, 42 points, pass at 34)

Write your answers in `practice/phase2/answers.md`.

### Q1 (2 pts)
```ruby
a = WhackTheMole::Score.new
b = WhackTheMole::Score.new
a.hit!
a.hit!
b.miss!
[a.total, b.total, a.hits + b.hits]
```
Predict the array, and explain in one sentence why `b` isn't affected by `a.hit!`.

_Covers: O2.1_

### Q2 (2 pts)
(a) What happens when code runs `score.hits = 10` on a `Score`? (b) Why is that a design choice and not an oversight?

_Covers: O2.2_

### Q3 (2 pts)
From inside `Window`, which of these calls on `@game` work? Pick all that apply.

a) `@game.click(10, 20, now: 0)`  b) `@game.spawn_mole(0)`  c) `@game.clock_label(0)`  d) `@game.whack_at(1, 2, 0)`

_Covers: O2.3_

### Q4 (2 pts)
A teammate proposes this change to `Window#button_down`:

```ruby
mole = @game.moles.find { |m| m.contains?(mouse_x, mouse_y) }
if mole
  mole.whack(Gosu.milliseconds)
  @game.score.hit!
end
```
Give two concrete problems with this design.

_Covers: O2.3_

### Q5 (2 pts)
(a) Why is `Hole.grid` a class method rather than an instance method? (b) In `HighScore#initialize(path: self.class.default_path)`, what does `self.class` refer to?

_Covers: O2.4_

### Q6 (3 pts)
```ruby
a = Hole.new(x: 1, y: 2)
b = Hole.new(x: 1, y: 2)
c = a.with(x: 5)
[a == b, a.equal?(b), ([a, c] - [b]).size, a.x]
```
Predict the array (`Hole` is `Data.define(:x, :y)`).

_Covers: O2.5_

### Q7 (2 pts)
Should each be a `Data` value object or a class? Justify each in one sentence.

(i) `ScreenShake`, holding `started_at`, `duration_ms` and `magnitude`, with an `offset(now)` method.
(ii) `Lives`, starting at 3 and going down by one each time a mole escapes.

_Covers: O2.5_

### Q8 (2 pts)
In `window.rb`, what does `super(Config::WIDTH, Config::HEIGHT)` in `initialize` do, and what does `else super` in `button_down` do?

_Covers: O2.6_

### Q9 (1 pt)
To reuse `hit!` and `miss!`, someone suggests `class Game < Score`. What's the best objection?

a) Ruby doesn't allow inheriting from your own classes.
b) A game isn't a score; it *has* one. Inheriting couples `Game` to `Score`'s internals and exposes `hit!` as part of `Game`'s interface.
c) Inheritance is slower than composition.
d) `Score` would need `attr_accessor`.

_Covers: O2.6_

### Q10 (2 pts)
`Game.new(random:, high_score:)`. What does the window pass for each, what do the tests pass, and why does the difference matter?

_Covers: O2.7_

### Q11 (2 pts)
Write the smallest class you could pass as `high_score:` that always reports a best of 0 and never touches a file. Which concept lets this work, and which two methods must it have?

_Covers: O2.8_

### Q12 (3 pts)
```ruby
def risky(kind)
  puts 'start'
  raise ArgumentError, 'bad' if kind == :arg
  1 / 0 if kind == :zero
  'ok'
rescue ArgumentError => e
  "rescued #{e.message}"
ensure
  puts 'done'
end
```
For `risky(:none)`, `risky(:arg)` and `risky(:zero)`, give what's printed and what's returned or raised.

_Covers: O2.9_

### Q13 (1 pt)
Why would `rescue` (bare, no class) in `HighScore#load` be worse than `rescue JSON::ParserError, SystemCallError`?

_Covers: O2.9_

### Q14 (2 pts)
Describe the steps `HighScore#save` takes to write the file, and the specific failure the extra step prevents.

_Covers: O2.10_

### Q15 (2 pts)
For each file content, what does `HighScore.new(path:).best` return? `{"best":7}`, `{"best":"7"}`, `[7]`, `{"best":0}`, `not json`. Why does `load` use `JSON.parse` and never `eval`?

_Covers: O2.10_

### Q16 (3 pts)
List three problems with this test.

```ruby
def test_score
  score = Score.new
  score.hit!
  score.hit!
  score.miss!
  assert_equal score.total, 1
  sleep 1
  assert score.hits == 2
end
```

_Covers: O2.11_

### Q17 (2 pts)
`game_test.rb` builds its game with `Random.new(1)` and a `HighScore` in `Dir.mktmpdir`. What would go wrong, specifically, with `Random.new` and `HighScore.new` (no arguments)?

_Covers: O2.12_

### Q18 (2 pts)
Put these TDD steps in order and say why the first step must be done before writing code: *make it pass with the simplest code*, *write a failing test and watch it fail*, *clean up while green*.

_Covers: O2.13_

### Q19 (2 pts)
```
lib/whack_the_mole/streak.rb:9:5: C: [Correctable] Style/StringLiterals: Prefer single-quoted strings when you don't need string interpolation or special symbols.
```
What does this offense mean, how do you fix it with one command, and why does a team care about a rule like this?

_Covers: O2.14_

### Q20 (3 pts)
Write a complete Minitest test method (code) that checks `RoundTimer#seconds_left` returns 60 at the start, 1 with 1 ms left, and 0 after the end, for a timer with `started_at: 500, duration_ms: 60_000`. Use explicit times.

_Covers: O2.11, O2.12_

---

## Part B: practical (open-book, autograded)

1. Copy [practical/practical_test.rb](practical/practical_test.rb) to `practice/phase2/practical_test.rb`.
2. Create `practice/phase2/practical.rb` with two top-level constants: a `Result` value object and a `ScoreHistory` class that keeps a player's recent scores in a JSON file. Read the tests: they're the specification.
3. Pass when `ruby practice/phase2/practical_test.rb` has 0 failures and 0 errors and `bundle exec rubocop practice/phase2` is clean.

| Tested behavior | Objectives |
|---|---|
| `Result` total, accuracy, value equality, `with`, no setters | O2.1, O2.5 |
| `ScoreHistory.default_path` | O2.4 |
| Public interface is exactly `add`, `average`, `scores` | O2.2, O2.3 |
| `path:` and `limit:` injected | O2.7 |
| Missing or corrupt files mean no scores | O2.9, O2.10 |
| Atomic save, persists across instances | O2.10 |
| `add('7')` raises `ArgumentError` | O2.9 |
| A failed save warns and keeps going | O2.9 |
| Callers can't change the stored scores | O2.2 |

---

## Part C: project (hit streaks)

Graded against your `phase-2-streaks` branch and `practice/phase2/design.md`. Every row must be **Meets** or **Exceeds**.

| Criterion | Below | Meets | Exceeds |
|---|---|---|---|
| Behavior | A rule from the project spec is missing or wrong | All six rules work in play and in tests | Edge cases tested: hit then escape in the same update; a whacked mole that finishes dropping doesn't count as escaped |
| Design | Streak rules live in `Window`, or state is exposed with writers | Rules live in game code; state is changed only through methods like `hit!`; window only reads | `design.md` compares two placements and justifies the choice with phase 2 ideas |
| Tests | Tests reach into private methods or instance variables, or depend on real time or unseeded randomness | Tests use only public interfaces, seeded `Random`, explicit times | Tests read as a spec: one behavior per test, names that say the rule |
| TDD evidence | No red commits | `git log` shows red commits followed by green ones for at least three behaviors | Every behavior followed the loop, with refactor commits where useful |
| Quality gate | Tests, RuboCop or the smoke launch fail | `rake test`, `rubocop` pass and the smoke launch exits 124 | |

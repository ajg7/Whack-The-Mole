# Phase 2 answer key

Don't open this until you've written every Part A answer. An answer earns the point if it states the key idea, even in different words.

## Part A

### Q1
`[2, -1, 2]` (1 pt). Each object has its own instance variables; `a.hit!` changes `a`'s `@hits` only (1 pt).

### Q2
(a) `NoMethodError`: there's no `hits=` method because `Score` only has `attr_reader` (1 pt). (b) Encapsulation: the only ways to change a score are `hit!` and `miss!`, so the scoring rules stay in one place and can't be bypassed (1 pt).

### Q3
**a and c** (2 pts; 1 pt if one is wrong). `spawn_mole` and `whack_at` are private.

### Q4
Any two (1 pt each):
- Game rules move into the window (CLAUDE.md: the window has no game rules), so they can't be tested without Gosu.
- It skips the hammer offset (`Hammer.hit_point`), `hittable?` (a hiding or already-whacked mole could be hit again), the miss penalty, the popup, and the countdown/state check.
- It reaches into `Game`'s collaborators (asks instead of tells), coupling the window to `Game`'s internals; changing scoring now means editing two places.

### Q5
(a) It builds the holes, so there's no `Hole` to call it on yet, and it needs no object's state (1 pt). (b) The object's class, `HighScore` (or a subclass); `default_path` is a class method so it's called on the class (1 pt).

### Q6
`[true, false, 1, 1]` (3 pts; 1 pt off per wrong element, minimum 0). `a == b` compares values; `equal?` compares identity; `[a, c] - [b]` removes `a` because it equals `b`, leaving `[c]`; `with` returns a new object and leaves `a` alone.

### Q7
(i) `Data`: its fields never change after creation; the offset is computed from `now` (like `Popup`) (1 pt). (ii) Class: its state changes over time and it has an identity (1 pt).

### Q8
`super(...)` calls `Gosu::Window#initialize` with the window size, so Gosu sets up the window (1 pt). `else super` passes buttons the game doesn't handle to `Gosu::Window#button_down`, keeping Gosu's default behavior (1 pt).

### Q9
**b.**

### Q10
Window: `Random.new` (unseeded) and `HighScore.new` (real file in the user data dir). Tests: `Random.new(1)` and `HighScore.new(path:)` in a temp dir (1 pt). It lets the same `Game` code be tested deterministically without touching the real high-score file (1 pt).

### Q11
```ruby
class NullHighScore
  def best = 0
  def record(_score) = 0
end
```
(1 pt for working code.) Duck typing: `Game` only calls `best` and `record`, so any object with those methods works (1 pt).

### Q12
- `risky(:none)`: prints `start`, `done`; returns `"ok"`.
- `risky(:arg)`: prints `start`, `done`; returns `"rescued bad"`.
- `risky(:zero)`: prints `start`, `done`; raises `ZeroDivisionError` (not rescued; `ensure` still runs).

1 pt each.

### Q13
A bare `rescue` catches every `StandardError`, including bugs like a `NoMethodError` from a typo, hiding them behind a silent `0`.

### Q14
`mkdir_p` the folder; write the JSON to `highscore.json.tmp`; `File.rename` the temp file over the real one (1 pt). A crash or power loss mid-write can't leave a half-written, corrupt `highscore.json`, because rename replaces the file in one step (1 pt).

### Q15
`7`, `0`, `0`, `0`, `0` (1 pt). `JSON.parse` only builds plain data; `eval` would run any Ruby code in the file, and the file is untrusted input (1 pt).

### Q16
Any three (1 pt each):
- `assert_equal score.total, 1` has the arguments backwards: expected comes first, or the failure message is misleading.
- `sleep 1` slows the suite and tests nothing; game logic takes time as an argument.
- `assert score.hits == 2` should be `assert_equal 2, score.hits` for a useful failure message.
- The name `test_score` doesn't say what behavior is tested.
- No blank line between act and assert; several behaviors in one test.

### Q17
`Random.new`: spawns differ every run, so tests that depend on which holes moles appear in would pass or fail at random (flaky) (1 pt). `HighScore.new`: tests would read and overwrite the developer's real high-score file, and results would depend on what's already in it (1 pt).

### Q18
Write a failing test and watch it fail → make it pass simply → refactor while green (1 pt). Seeing it fail proves the test can detect the missing behavior; a test that passes before the code exists might test nothing (1 pt).

### Q19
Use single quotes for a string with no interpolation or escapes (1 pt). `bundle exec rubocop -a` (1 pt is shared with the reason). Consistent style keeps diffs about logic and makes code read the same everywhere (1 pt for command + reason).

### Q20
```ruby
def test_seconds_left_counts_down_to_zero
  timer = RoundTimer.new(started_at: 500, duration_ms: 60_000)

  assert_equal 60, timer.seconds_left(500)
  assert_equal 1, timer.seconds_left(60_499)
  assert_equal 0, timer.seconds_left(60_500)
end
```
1 pt per correct assertion (right times, expected value first). `60_499` is 1 ms before the end.

## Part B

Reference solution: [phase2_practical.rb](phase2_practical.rb). Notes:

- `Result` as `Data.define` gives `==`, `with` and no setters for free.
- `scores` returns `@scores.dup` so callers can't change the history. Returning a frozen array also passes.
- `load` checks the shape (`is_a?(Hash)`, `is_a?(Array)`, `all?(Integer)`) instead of rescuing `NoMethodError`/`TypeError`, which would hide bugs (Q13).
- `add` raises `ArgumentError` *before* changing anything.
- The test for a failed save puts a file where the folder should be, so `mkdir_p` raises a `SystemCallError`.

# Phase 1 answer key

Don't open this until you've written every Part A answer. When grading, an answer earns the point if it states the key idea, even in different words.

## Part A

### Q1
**b.** `Gemfile` holds the ranges you edit; `Gemfile.lock` is Bundler's record of exact versions and is committed for an app.

### Q2
(a) `bundle exec` runs Rake and the tests with exactly the gem versions in `Gemfile.lock`, not whatever versions happen to be installed globally. (1 pt)
(b) It runs the tests: the `Rakefile` sets `task default: :test`. (1 pt)

### Q3
**c.** A state is an identifier from a fixed set chosen in code. The others are text from a person, text for a person, or a path.

### Q4
`59`, `60`, `3.5`, `-4` (1 pt each). Integer division floors, so `-7 / 2` is `-4`, not `-3`.

### Q5
`60000`, `1`, `"1:00"` (1 pt each). At `now = 500` the round hasn't started, so `now - started_at` is `-500` and `60_000 - (-500)` is `60_500`; `clamp(0, @duration_ms)` caps it at `60_000`. At `60_999`, 1 ms remains, and `ceil` turns `0.001` seconds into `1`.

### Q6
(a) `free_holes` local, `@random` instance variable, `SPAWN_INTERVAL_MS` constant (1 pt for all three). (b) It raises `FrozenError` (1 pt) because the array was frozen with `.freeze`; the constant alone would only stop reassigning the name (1 pt).

### Q7
`Score: #{total}` (single quotes don't interpolate) and `0:07`. 1 pt each.

### Q8
Nothing; it returns `nil` (1 pt). `case` checks `:countdown` and `:playing`; no `when` matches `:title` and there's no `else`, so no branch runs (1 pt).

### Q9
`:rising`, `:up`, `:up`, `:hiding`, `:hiding`, `:gone`. Boundaries: `up` starts at 240, `hiding` at 240 + 600 = 840, `gone` at 2 × 240 + 600 = 1080.

### Q10
`0`, `""`, `[]`, `:false` are truthy. Only `nil` and `false` are falsy. (2 pts if exactly right; 1 pt for one mistake.)

### Q11
Nothing happens: `@song` is `nil` and `&.` skips the call and returns `nil` (1 pt). It says "do this only if it exists" in one short expression, so a missing audio file is skipped silently as the spec requires, without an `if` around every use (1 pt).

### Q12
1. Raises `ArgumentError`: positional arguments given, but the method only takes keywords.
2. Works: keyword order doesn't matter.
3. Raises `ArgumentError`: missing required keyword `high_score:`.

(2 pts for all three, 1 pt for two.)

### Q13
**b.** `past_half?`: snake_case, and `?` marks a method that returns true/false.

### Q14
(a) `[76, 22]`, since the offset is `[-24, -28]`. (b) `x = 76`, `y = 22`, `now = 900`; the splat spreads the array into two arguments.

### Q15
4 holes (1 pt). `GRID_LEFT = (640 - 3 × 192) / 2 = 32`. First hole (row 0, col 0): `x = 32 + (192 × 0.5) = 128`, `y = 120 + 96 = 216`. Second (row 0, col 1): `x = 32 + (192 × 1.5) = 320`, `y = 216` (1 pt). Order is row by row because `rows.product(cols)` varies the column fastest.

### Q16
(a) `3` (`[1, 3, 4]`). (b) Yes: a `Random` with the same seed produces the same sequence. The game injects a `Random` so tests can use a fixed seed and get repeatable spawns.

### Q17
`[0, 1, 2]`, `[0, 1, 2, 3]`, `true`, `false`.

### Q18
`nil` and `9` (1 pt). JSON keys are strings, so `JSON.parse` returns `{"best" => 9}`; the symbol `:best` is a different key (1 pt).

### Q19
`[18, 14]` and `nil`.

### Q20
`5` and `:fallback` (1 pt). `Window#load_audio` (1 pt).

### Q21
`a` is `[2, 4]` and `b` is `[1, 3]` (1 pt). Only `a.reject!(&:odd?)` changed `a`; `reject` built a new array (1 pt).

### Q22
It's a namespace: the game's class names (`Game`, `Window`, `Score`) can't collide with classes of the same name from Ruby or gems.

### Q23
(a) `json` is a library found by name in Ruby's standard library; `config` is a file of this project, found by its path relative to the requiring file (1 pt). (b) `'assets'` would be relative to the directory you launched the game from, so running it from anywhere but the repo root would fail to find images; `expand_path` anchors it to the source file's location (1 pt).

## Part B

Reference solution: [phase1_practical.rb](phase1_practical.rb). Other correct solutions are fine if the tests pass and RuboCop is clean. Notes:

- `clock_label`: same idea as `RoundTimer#clock_label`. `ceil` before `divmod`.
- `remove_expired!` must return `ages` explicitly: `reject!` returns `nil` when it removes nothing.
- `shout`: `text << '!'` would raise `FrozenError` because of the magic comment in the test file. Build a new string.
- `fallback` must rescue only `RuntimeError` (what `raise 'message'` raises), which is why the `ZeroDivisionError` test expects the error to escape.

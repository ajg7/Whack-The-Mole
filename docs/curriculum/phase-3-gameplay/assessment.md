# Phase 3 summative assessment: gameplay programming

Pass all three parts to unlock phase 4. See [the README](../README.md#passing-a-gate) for the rules.

All `Config` values are the ones in `lib/whack_the_mole/config.rb` as committed.

---

## Part A: written (closed-book, 42 points, pass at 34)

Write your answers in `practice/phase3/answers.md`.

### Q1 (2 pts)
Name the three steps of a game loop in order, and the Gosu callback in `Window` that handles each.

_Covers: G3.1_

### Q2 (2 pts)
A teammate moves `@game.update(Gosu.milliseconds)` from `Window#update` into the top of `Window#draw`, "since they both run every frame anyway". Give two things that go wrong.

_Covers: G3.1_

### Q3 (1 pt)
Popups are drawn at z 4 and moles at z 2. What would the player see if the hammer were drawn at z 1 instead of 10?

_Covers: G3.1_

### Q4 (3 pts)
A different game keeps a mole up for "72 updates". How long is the mole up at 60, 30 and 144 updates per second?

_Covers: G3.2_

### Q5 (2 pts)
(a) What does "pass time in" mean in this codebase? (b) Why does `Mole` store `@spawned_at` instead of a frame counter it increments each update?

_Covers: G3.2_

### Q6 (1 pt)
Which behavior is the best fit for delta time (`x += speed * dt`) rather than stored timestamps?

a) How long a mole stays up  b) The 60-second round  c) A cloud drifting across the sky forever  d) The popup fade

_Covers: G3.2_

### Q7 (3 pts)
```ruby
game = Game.new(random: Random.new(1), high_score: high_score)
game.click(0, 0, now: 0)
game.click(0, 0, now: 500)
game.update(3000)
game.update(63_000)
game.click(0, 0, now: 63_500)
game.click(0, 0, now: 64_000)
```
Give `game.state` after each of the six calls. (Half a point each.)

_Covers: G3.3_

### Q8 (2 pts)
`Window#sync_music` starts with `return if @game.state == @previous_state`. What is this technique called, and what bug would appear without that line?

_Covers: G3.3_

### Q9 (1 pt)
Why is the screen state one Symbol instead of booleans like `@playing` and `@game_over`?

_Covers: G3.3_

### Q10 (2 pts)
Suppose `Game#update_round` no longer ran `moles.reject! { |mole| mole.gone?(now) }`. Describe what the player would see after the first two moles hide, and explain why.

_Covers: G3.4_

### Q11 (3 pts)
A mole with `spawned_at: 0, up_ms: 1000` is whacked at 1000. Give `frame(now)` at 1000, 1039, 1040 and 1080, and `phase(now)` at 1120.

_Covers: G3.5_

### Q12 (2 pts)
(a) What does `retro: true` in `load_tiles` do, and why does this game need it? (b) Write the frame-index expression for a 4-frame animation that loops every 400 ms, given `elapsed` in ms.

_Covers: G3.5_

### Q13 (3 pts)
A mole is up in the hole at `(128, 216)`. (a) What are `left` and `top`? (b) What are the left, right, top and bottom edges of its hit box? (c) Does a click at `(150, 190)` hit it? Show the hit point.

_Covers: G3.6_

### Q14 (2 pts)
(a) Why is the hit box smaller than the 144×144 sprite? (b) Why is the click shifted by `HAMMER_HEAD_OFFSET` before testing?

_Covers: G3.6_

### Q15 (2 pts)
Name the three spawn rules in `update_round`/`spawn_mole` (where, how many, when). Why is the `Random` passed in rather than created inside `spawn_mole`?

_Covers: G3.7_

### Q16 (2 pts)
(a) What is `up_ms` when the clock shows `0:30`, and when it shows `0:15`? (b) The designer wants the round to stay easy longer, then get hard quickly near the end. What one change to the formula achieves that?

_Covers: G3.8_

### Q17 (3 pts)
150 ms after a popup starts, what are `progress`, `offset` and `alpha`?

_Covers: G3.9_

### Q18 (2 pts)
List three pieces of feedback the game gives on a hit, and explain the problem `GAME_OVER_LOCKOUT_MS` solves.

_Covers: G3.9_

### Q19 (2 pts)
A teammate adds `require 'gosu'` to `mole.rb` and calls `Gosu.milliseconds` inside `Mole#phase` "to save passing `now` around". Give two consequences.

_Covers: G3.10, G3.2_

### Q20 (2 pts)
For each failure, give the game's response and why: (a) the music file is missing, (b) `mole-sheet.png` is missing, (c) saving the high score fails, (d) the high-score file contains `{"best":"lots"}`. (Half a point each.)

_Covers: G3.11_

---

## Part B: practical (open-book, autograded)

1. Copy [practical/practical_test.rb](practical/practical_test.rb) to `practice/phase3/practical_test.rb`.
2. Create `practice/phase3/practical.rb` with: `Rect` (a value object with `contains?` and `overlaps?`), `lerp` and `ease_out`, `frame_at`, `Flow` (the screen state machine), and `ScreenShake`. Read the tests: they are the specification.
3. Pass when `ruby practice/phase3/practical_test.rb` has 0 failures and 0 errors and `bundle exec rubocop practice/phase3` is clean.

Rule: no `require 'gosu'`, and no reading the clock (`Time.now`, `Gosu.milliseconds`). Time and randomness come in as arguments.

| Tested behavior | Objectives |
|---|---|
| `Rect#contains?` (edges inclusive), `#overlaps?` (shared area only) | G3.6, O2.5 |
| `lerp`, `ease_out` (clamped) | G3.8, G3.9 |
| `frame_at(elapsed, frame_ms:, frames:, repeat: false)` | G3.2, G3.5 |
| `Flow#fire(event)`, ignored events, `changed?` | G3.3 |
| `ScreenShake#offset(now, random:)`, `#active?(now)` | G3.2, G3.7, G3.9 |

---

## Part C: project (the golden mole)

Graded against your `phase-3-golden-mole` branch and `practice/phase3/playtest.md`. Every row must be **Meets** or **Exceeds**.

| Criterion | Below | Meets | Exceeds |
|---|---|---|---|
| Rules | A rule from the project spec is missing or wrong | All six rules work in play and in tests | Golden chance and up-time factor are config values, and changing them needs no other edit |
| Architecture | `gosu` required in a rule file, or rules decided in `Window` | Rules in game code, window only reads state to tint, label and pitch | The golden/normal difference lives in one place (for example a `golden?` mole and a `points` method), not scattered `if`s |
| Time and randomness | Reads the clock or uses unseeded randomness in rules | All golden behavior uses `now` and the injected `Random`; tests use fixed seeds and times | A test proves the golden chance is roughly 1 in 8 over many seeded spawns |
| Feel | No visible or audible difference | Tint, "+3" popup and higher pitch all present | A further touch (a sparkle, a bigger or slower popup) with a sentence on why it helps |
| Play-test log | Missing | Three rounds recorded, fairness judged, one tuning experiment with numbers and outcome | The tuning experiment changes your final config, with reasoning |
| Quality gate | Tests, RuboCop or the smoke launch fail | All pass, smoke launch exits 124 | |

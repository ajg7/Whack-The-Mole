# Whack-The-Mole v1: developer assessment (Slowbro)

Scope: the code the agents built from base commit `25d9134` to `04a6cc7` (round 1 build `6198f8c`, tester `17ddf57`, round 2 fixes `6c32abf`, tester `04a6cc7`), plus the reasons recorded in `docs/spec.md`, `docs/review/plan.md` and the round review, adversary, verdict, fixes and tester files. Later hand edits (hit box size, hole drawing) are not tested; questions are worded so they hold for the current code.

20 questions, multiple choice, one correct answer each. The answer key is at the end.

---

### Q1. Hit box units (config.rb)

`config.rb` defines the mole's hit box like this (numbers omitted):

```ruby
HIT_LEFT = <n> * SCALE
HIT_TOP = <n> * SCALE
HIT_WIDTH = <n> * SCALE
HIT_HEIGHT = <n> * SCALE
```

What does the number before `* SCALE` measure, and why was the box added?

- A. Screen pixels; it was added so the hit box could be bigger than the drawn sprite.
- B. Sprite (art) pixels inside the 36x36 mole frame; round 2 replaced the full 144x144 sprite rect with a box around the mole's opaque pixels.
- C. Grid cells; it lets a click anywhere in the hole's cell count as a hit.
- D. Milliseconds; it sets how long the mole stays hittable at each edge.

Source: `lib/whack_the_mole/config.rb:23-26`, `docs/review/round-2-fixes.md` (item 6), `docs/review/round-2-review.md`

### Q2. The game-over lockout (config.rb, game.rb)

```ruby
when :game_over then start(now) if now - @finished_at >= Config::GAME_OVER_LOCKOUT_MS
```

Why does this one-second lockout exist?

- A. The spec requires a 1 second pause before the game-over text appears.
- B. Saving the high score takes time, and a restart during the save would corrupt the file.
- C. A player still clicking when the timer hit 0 would restart at once and never see the game-over screen.
- D. Gosu sends two `button_down` events per click, and the lockout drops the duplicate.

Source: `lib/whack_the_mole/game.rb:29`, `lib/whack_the_mole/config.rb:30`, `docs/review/round-1-review.md` (MINOR 1), `docs/review/round-2-fixes.md` (item 1)

### Q3. Clicks during the countdown (game.rb)

What does `Game#click` do when the state is `:countdown`?

- A. It swings the hammer and returns `nil`; the score, hits and misses do not change.
- B. It counts as a miss (-1), because no mole can be up yet.
- C. It skips the rest of the countdown and starts play.
- D. It raises an error, because `click` has no `:countdown` branch.

Source: `lib/whack_the_mole/game.rb:25-32`, `docs/spec.md` (rule 1)

### Q4. Clicking a whacked or hiding mole (game.rb)

```ruby
mole = moles.find { |candidate| candidate.contains?(x, y) }
return miss unless mole
return unless mole.hittable?(now)
```

A player double-clicks a mole. The first click is a hit. What does the second click do, and why?

- A. It is a miss (-1), because the spec says a click that hits no mole is -1.
- B. It is a second hit (+1), because the mole is still on screen.
- C. It restarts the mole's rise animation.
- D. It is ignored (returns `nil`, no score change); round 1's adversary showed a double click netted zero points, and round 2 changed it.

Source: `lib/whack_the_mole/game.rb:82-91`, `docs/review/round-1-adversary.md` (new MINOR 1 and 2), `docs/review/round-2-fixes.md` (items 4 and 5)

### Q5. How long a mole stays up (game.rb, round_timer.rb)

```ruby
up_ms = Config::UP_MS_START + ((Config::UP_MS_END - Config::UP_MS_START) * @round.elapsed_fraction(now))
```

With `UP_MS_START = 1200` and `UP_MS_END = 600`, what is `up_ms` for a mole spawned exactly halfway through the round?

- A. 600
- B. 1050
- C. 900
- D. 1200

Source: `lib/whack_the_mole/game.rb:77`, `lib/whack_the_mole/round_timer.rb:20-22`, `docs/spec.md` (rule 3)

### Q6. The clock label (round_timer.rb)

The round starts 3000 ms after the title click. At 3500 ms (half a second into play), what does `clock_label` show?

- A. `0:59`
- B. `1:00`
- C. `0:60`
- D. `0:59.5`

Source: `lib/whack_the_mole/round_timer.rb:24-31`, `docs/review/tester-report.md` (Notes)

### Q7. Which moles can be hit (mole.rb)

`Mole#phase(now)` returns `:rising`, `:up`, `:hiding`, `:dropping` or `:gone`. In which phases does `hittable?(now)` return true for a mole that has not been whacked?

- A. Only `:up`
- B. `:rising`, `:up` and `:hiding`
- C. Every phase except `:gone`
- D. `:rising` and `:up`

Source: `lib/whack_the_mole/mole.rb:47-49`, `docs/review/plan.md` (Mole section)

### Q8. Why moles store timestamps (mole.rb)

A `Mole` stores `spawned_at` and works out its phase and frame from `now`. It never counts frames. Why?

- A. Spec rule 10: logic runs on elapsed milliseconds passed in from the window, so behavior is the same at any frame rate and tests can pass literal times.
- B. Gosu does not report a frame number, so a counter is impossible.
- C. Timestamps use less memory than an integer counter.
- D. It lets `Mole` call `Gosu.milliseconds` directly without the window.

Source: `lib/whack_the_mole/mole.rb:11-35`, `docs/spec.md` (rule 10), `docs/review/plan.md` (section 2, "Time model")

### Q9. The hammer's hit point (hammer.rb)

```ruby
def self.hit_point(x, y)
  dx, dy = Config::HAMMER_HEAD_OFFSET
  [x + dx, y + dy]
end
```

What is this for?

- A. It moves the drawn hammer sprite so it is centered on the cursor.
- B. It turns the mouse position into the hammer head's position, and `Game#click` tests moles against that point, not the raw mouse position.
- C. It clamps the mouse to the window so clicks outside it are ignored.
- D. It converts screen pixels to grid row and column numbers.

Source: `lib/whack_the_mole/hammer.rb:7-10`, `lib/whack_the_mole/game.rb:30`, `docs/spec.md` (rule 6)

### Q10. Loading the best score (high_score.rb)

```ruby
data.is_a?(Hash) && data['best'].is_a?(Integer) && data['best'].positive? ? data['best'] : 0
```

Which file content loads as a best score that is not 0?

- A. `{"best":7}`
- B. `{"best":"9"}`
- C. `{"best":2.5}`
- D. `[7]`

Source: `lib/whack_the_mole/high_score.rb:29-34`, `docs/review/round-2-fixes.md` (item 2), `test/whack_the_mole/round2_behavior_test.rb`

### Q11. Atomic save (high_score.rb)

`HighScore#save` writes to `"#{@path}.tmp"` first and then calls `File.rename`. Why not write straight to the real file?

- A. Windows won't let Ruby write a `.json` file directly.
- B. The `.tmp` file is a backup the game reads if the main file is corrupt.
- C. `JSON.generate` can only write to a new file.
- D. If the game crashes mid-write, only the temp file is damaged; the rename swaps in a complete file, so the saved best is never left half-written (spec rule 8).

Source: `lib/whack_the_mole/high_score.rb:36-43`, `docs/spec.md` (rule 8), `docs/review/plan.md` (HighScore section)

### Q12. Testing the high score without touching real data (tests)

The high-score tests never read or write `%APPDATA%\WhackTheMole\highscore.json`. How?

- A. They stub `ENV['APPDATA']` with a fake environment library.
- B. `HighScore` skips saving when it detects Minitest is loaded.
- C. `HighScore.new(path:)` takes the path as a keyword argument, so tests pass a file inside `Dir.mktmpdir` and delete it in `teardown`.
- D. They run only on CI, where `APPDATA` does not exist.

Source: `lib/whack_the_mole/high_score.rb:14-17`, `test/whack_the_mole/round2_behavior_test.rb`, `test/whack_the_mole/high_score_edge_cases_test.rb`, `docs/review/plan.md` (section 2)

### Q13. Finding free holes (hole.rb)

```ruby
free_holes = Hole.grid - moles.map(&:hole)
```

`Hole.grid` builds brand-new `Hole` objects every call. Why does subtracting the moles' holes still work?

- A. `Hole` is a `Data.define` value object, so two holes with the same `x` and `y` are equal even if they are different objects.
- B. `Hole.grid` caches its array, so the same objects come back each time.
- C. Array subtraction compares only the `x` coordinate.
- D. It does not work; a mole can spawn in an occupied hole.

Source: `lib/whack_the_mole/hole.rb:4-11`, `lib/whack_the_mole/game.rb:76`, `docs/review/plan.md` (Hole section)

### Q14. The floating "+1" (popup.rb)

`Popup` is `Data.define(:x, :y, :started_at)`, so its fields can't change. How does the "+1" float upward and fade?

- A. The window moves `popup.y` up by a few pixels each frame.
- B. `Game#update` replaces each popup with a new one that has a smaller `y` every frame.
- C. Gosu fades and moves fonts on its own after `draw_text_rel`.
- D. `offset(now)` and `alpha(now)` are computed from how much of `POPUP_MS` has passed since `started_at`, and the window draws at `y + offset(now)`.

Source: `lib/whack_the_mole/popup.rb:4-20`, `lib/whack_the_mole/window.rb:109-114`

### Q15. Hits and misses (score.rb)

`Score` keeps `hits` and `misses` and computes `total` as `hits - misses`. Why not keep one integer that goes up and down?

- A. Ruby integers can't go negative inside an `attr_reader`.
- B. The spec counts hits and misses separately (the game-over screen shows both), and the total can still go negative.
- C. Keeping two counters makes `total` faster to compute.
- D. The high score file stores hits and misses, not the total.

Source: `lib/whack_the_mole/score.rb:4-23`, `docs/spec.md` (rules 4 and 7)

### Q16. Choosing the thud pitch (window.rb)

```ruby
when Gosu::MS_LEFT then play_thud(@game.click(mouse_x, mouse_y, now: Gosu.milliseconds))
```

How does the window know whether to play the normal or the low thud?

- A. `Game#click` returns `:hit`, `:miss` or `nil`, and `play_thud` maps that to a speed of 1.0 or `MISS_SPEED`; game rules never touch audio.
- B. `Game` holds the `Gosu::Sample` and plays it inside `whack_at`.
- C. The window compares the score before and after the click.
- D. The window checks whether the mouse is over a hole.

Source: `lib/whack_the_mole/window.rb:31-37`, `lib/whack_the_mole/window.rb:94-97`, `docs/review/plan.md` (section 2, "Sound events")

### Q17. Missing images vs missing audio (window.rb)

```ruby
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
```

Why does a missing PNG stop the game while a missing MP3 does not?

- A. Gosu raises for missing PNGs but never for missing MP3s.
- B. The `.aseprite` sources are the fallback for images, so `abort` is never actually reached.
- C. The spec says audio may be skipped silently, but the game can't run without its sprites; round 2 added a clear one-line message instead of a stack trace.
- D. `abort` is used for images so the high score is saved before exiting.

Source: `lib/whack_the_mole/window.rb:61-71`, `docs/spec.md` (rule 9), `docs/review/round-2-fixes.md` (item 7), `docs/review/round-1-adversary.md` (new MINOR 5)

### Q18. Pressing R during the lockout (window.rb, round2_behavior_test.rb)

The round has just ended and the 1 s lockout is still running. The player presses R. What happens?

- A. Nothing until the lockout ends, like a click.
- B. A new countdown starts at once: the window's `restart` swings the hammer and calls `Game#start`, which has no lockout check.
- C. The R press is queued and runs when the lockout ends.
- D. It counts as a miss on the old round.

Source: `lib/whack_the_mole/window.rb:34`, `lib/whack_the_mole/window.rb:55-59`, `test/whack_the_mole/round2_behavior_test.rb` (`test_explicit_start_bypasses_lockout`), `docs/review/round-2-fixes.md` (items 1 and 3)

### Q19. Where Gosu is required (lib/whack_the_mole.rb, bin, test_helper.rb)

`lib/whack_the_mole.rb` requires every game file but not `gosu`. `bin/whack_the_mole` requires `window.rb`, and `test/test_helper.rb` requires `lib/whack_the_mole`. Why is it split this way?

- A. Gosu must be required last, after all game classes are loaded.
- B. Requiring Gosu twice raises an error, so only one file may do it.
- C. `bin/whack_the_mole` cannot use `require_relative`.
- D. Only `window.rb` touches Gosu, so the tests load the game rules without opening a window or needing Gosu at all.

Source: `lib/whack_the_mole.rb`, `bin/whack_the_mole`, `test/test_helper.rb`, `docs/review/plan.md` (section 2)

### Q20. Tooling (Rakefile, Gemfile, .rubocop.yml, .gitignore)

Which statement about the tooling the agents set up is correct?

- A. `Gemfile.lock` is listed in `.gitignore` because the project is packaged as a gem.
- B. The `Rakefile` sets `t.pattern = 'test/**/*_test.rb'` because the default pattern (`test/test*.rb`) would miss files named `*_test.rb`.
- C. `.rubocop.yml` turns off `Style/FrozenStringLiteralComment` so files don't need the magic comment.
- D. `rubocop-minitest` is in the Gemfile to make the test suite run faster.

Source: `Rakefile`, `Gemfile`, `.rubocop.yml`, `.gitignore`, `docs/review/plan.md` (section 4, step 1), `docs/spec.md` (Repo hygiene)

---

## Answer Key

1. **B.** The numbers are measured in the 36x36 art and scaled by `SCALE` (4) to screen pixels; round 2 item 6 replaced the full 144x144 rect with the mole's opaque bounds, so clicks on transparent padding no longer hit. A is tempting because the result is in screen pixels, but the number itself is in art pixels, and the change made the box smaller than the sprite.
2. **C.** Round 1's reviewer noted that a click on game over restarted at once, so a player still clicking at 0:00 skipped the results; round 2 added `GAME_OVER_LOCKOUT_MS`. A is wrong: the spec has no such pause, and the text shows right away. Only restart clicks are blocked.
3. **A.** `click` always calls `hammer.swing(now)`, and the `case` has no `:countdown` branch, so it returns `nil` and nothing is scored (spec rule 1). D is tempting, but a Ruby `case` with no matching `when` just returns `nil` and doesn't raise.
4. **D.** The mole is found but `hittable?` is false once whacked, so `return unless mole.hittable?(now)` returns `nil` with no score change. A was the round 1 behavior (`hittable?` was part of the search, so the click fell through to `miss`), which the adversary flagged and round 2 fixed.
5. **C.** Halfway, `elapsed_fraction` is 0.5, so 1200 + (600 - 1200) * 0.5 = 900. B is a halfway guess with no basis in the formula, and A/D are the end and start values.
6. **B.** `seconds_left` rounds remaining seconds up (`ceil`): 59.5 s left shows as 60, which `divmod(60)` turns into `1:00`. A is what you get if you round down; the tester noted the ceil choice matches the spec's `1:00, 0:59, ...` sequence.
7. **D.** `hittable?` is `!whacked? && %i[rising up].include?(phase(now))`. B is tempting because a hiding mole is still visible, but round 2 kept hiding moles unhittable and made clicks on them ignored, not misses.
8. **A.** The plan's time model passes `now` into every call and stores timestamps, so frame rate doesn't change behavior and tests can step time with literal numbers. D is the opposite of the rule: game logic never reads `Gosu.milliseconds` itself; only the window does.
9. **B.** `hit_point` adds `HAMMER_HEAD_OFFSET` to the mouse position, and `Game#click` passes that point to `whack_at` (spec rule 6: "the hit point is the hammer head"). A is tempting, but the drawn sprite is positioned in `Window#draw_hammer`, not by `hit_point`.
10. **A.** Only a Hash whose `"best"` is a positive Integer is kept. B (a string) and C (a float) fail `is_a?(Integer)`, which round 2 item 2 checks, and D is not a Hash.
11. **D.** Writing to a temp file and then renaming means the real file is always either the old version or the full new one (spec rule 8). B is tempting, but the `.tmp` file is renamed away and is never read; a tester case checks that none is left behind.
12. **C.** The path is injected (`path:` defaults to `default_path`), so tests point it at a temp directory. A is tempting, but the tests don't touch `ENV` at all; injection makes that unnecessary.
13. **A.** `Data.define` classes compare by value, so `Array#-` removes holes with the same `x` and `y`. B is wrong: `Hole.grid` builds new objects every call, and value equality is what makes the subtraction work.
14. **D.** Nothing is changed; `progress(now)` drives `offset` and `alpha`, and the window draws at `popup.y + popup.offset(now)`. A is how a frame-based design would do it, but `Data.define` fields can't be changed, and the time model avoids per-frame changes.
15. **B.** Spec rule 4 says hits and misses are counted separately, and rule 7 shows both on game over; `total` is derived and can go below 0. D is wrong: the high-score file stores only `{"best": n}`.
16. **A.** The plan's "Sound events" design has `click` return a symbol and the window map it to a sound, so game rules never know audio exists. B would break the rule that only `window.rb` uses Gosu.
17. **C.** Spec rule 9 makes audio optional ("skipped silently"), but sprites are required, so round 2 item 7 replaced the crash with a one-line `abort` message. A is wrong: both rescue the same `RuntimeError`, and they differ only in what they do next.
18. **B.** R calls `restart` only in `:game_over`, and `restart` calls `@game.start(now)` directly, skipping the lockout check in `click`. The fixes file asked for exactly this ("R key still restarts immediately"), and a tester test checks it. A is tempting, but only clicks have the lockout.
19. **D.** The architecture keeps Gosu in `window.rb` so the game rules are plain Ruby; `test_helper.rb` loads `lib/whack_the_mole` and never Gosu, so tests run without a window. B is wrong: a second `require` of the same library is simply a no-op in Ruby.
20. **B.** The plan says the default Rake pattern would skip `*_test.rb` files, so it sets the pattern. A is wrong: the spec says to commit `Gemfile.lock` because this is an app, and the plan keeps `rubocop-minitest` because Minitest 6 removed `assert_equal nil` (not for speed).

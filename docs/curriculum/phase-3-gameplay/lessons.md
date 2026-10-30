# Phase 3: Gameplay programming

**Driving question:** What makes a game feel fair, responsive and alive?

You now know the Ruby. This phase is about the craft of games: the loop that runs 60 times a second, why time beats frame counts, how a handful of symbols becomes a state machine, how sprites animate, how a click becomes a hit, how difficulty ramps, and the small touches ("juice") that make whacking a mole satisfying. Every idea is already in this game; you'll find it, explain it, and then use all of it to add a new kind of mole.

---

## Lesson 3.1: The game loop

### Objectives
- **[G3.1]** Describe the game loop (input, update, draw, repeated about 60 times a second) and map Gosu's callbacks (`button_down`, `update`, `draw`) onto it, explaining why `draw` must not change game state.

### Read
`lib/whack_the_mole/window.rb` (`update`, `draw`, `button_down`), `bin/whack_the_mole`.

### Concept
Almost every real-time game runs the same loop until the player quits:

```
loop do
  handle input      # what did the player do since last time?
  update            # advance the world: move things, apply rules
  draw              # show the world as it is now
end
```

`Window.new.show` starts Gosu's version of that loop. Gosu calls your methods:

| Gosu callback | Loop step | In this game |
|---|---|---|
| `button_down(id)` | input (an event, once per press) | left click → `@game.click`; `R` → restart |
| `update` | update (about every 16.7 ms by default, ~60 times a second) | `@game.update(Gosu.milliseconds)`, then music |
| `draw` | draw (after update, when the screen refreshes) | grass, holes, moles, popups, HUD, hammer |

**`draw` is read-only.** It should only *look at* state and paint it. If `draw` changed state, how the game played would depend on how often the screen redraws: a fast monitor would play differently from a slow one, and skipped frames would skip rules. All changes go through `update` and input handlers. In this game `Window#draw` only reads from `@game`.

**Input as events vs polling.** `button_down` is an *event*: called once per press. Some games instead *poll* every update (`Gosu.button_down?(Gosu::KB_LEFT)`) for held keys. Clicking a mole is a single action, so events fit. Note the game reads `mouse_x`/`mouse_y` at the moment of the click.

**Layers (z-order).** Every Gosu draw call takes a `z` value; higher z is drawn on top. Here: grass 0, holes 1, moles 2, popups 4, HUD 5, hammer 10, so the hammer is always on top.

### Try it
1. Add `puts Gosu.milliseconds` to `Window#update` temporarily and run the game for a second. How far apart are the numbers? Remove it after.
2. Find each z value in `window.rb` and confirm the table above.
3. Predict what you'd see if moles were drawn at z 11.

### Check yourself
1. Name the three steps of the game loop and the Gosu method for each.
2. Why must `draw` never change game state?
3. Why is a mouse click handled in `button_down` instead of being checked in `update`?

---

## Lesson 3.2: Time, not frames

### Objectives
- **[G3.2]** Explain frame-rate independence, and implement time-based behavior by passing the current time in and storing timestamps, not counting frames.

### Read
`Mole#phase` and `#frame`, `Hammer#frame`, `RoundTimer`, `Game#update` and `#start`, rule 10 in `docs/spec.md`.

### Concept
A naive game counts frames: "the mole stays up for 72 updates". At 60 updates per second that's 1.2 s. But if the computer is slow and only manages 30, it's 2.4 s, and the game gets easier on slow machines. On a 144 Hz monitor with an uncapped loop, it's 0.5 s.

This game ties everything to **elapsed milliseconds** instead. Two techniques:

1. **Pass time in.** The window reads the clock once, `Gosu.milliseconds`, and passes it as `now` to everything. Game code never reads the clock itself. That makes it testable (phase 2) *and* consistent: everything in one update sees the same `now`.
2. **Store when, compute what.** A mole doesn't store "I'm on frame 2" and change it every update. It stores `@spawned_at` (and `@whacked_at`) and *computes* its phase and frame from `now - @spawned_at` whenever asked. `RoundTimer` stores `started_at` and computes `remaining_ms(now)`. There's nothing to update, so nothing can drift or get out of sync.

```ruby
age = now - @spawned_at
if age < TRANSITION_MS then :rising
elsif age < TRANSITION_MS + @up_ms then :up
...
```

The alternative is **delta time**: each update gets `dt` (ms since last update) and does `x += speed * dt`. That's the right tool for continuous motion (a ball moving across the screen). For things with a start and an end, like a mole's life or a round, timestamps are simpler and exact.

**The catch.** Time only advances when `update` runs. `Game#update_round` spawns a mole when `now >= @next_spawn_at`, then sets `@next_spawn_at = now + 500`. If an update arrives 10 ms late, that spawn and every one after shifts 10 ms later. The *rules* are right at any frame rate, but events can only happen on an update. At 60 fps that's at most ~17 ms late, which nobody notices.

### Try it
1. `Mole.new(hole: Hole.new(x: 0, y: 0), spawned_at: 0, up_ms: 1000)`. Call `phase` and `frame` at 0, 100, 500, 1300, 1500. Now call them in a different order. Does order matter? Why not?
2. Write a frame-counting version of `Hammer#frame` on paper. What would happen to the swing at 30 fps?
3. In `game_test.rb`, find the test that jumps straight from `update(3000)` to `update(63_000)`. Why is that allowed?

### Check yourself
1. What does "frame-rate independent" mean? Give one way the game achieves it.
2. Why does `Mole` store `@spawned_at` instead of a frame counter?
3. When is delta time a better tool than timestamps?

---

## Lesson 3.3: State machines

### Objectives
- **[G3.3]** Model screens and entity behavior as finite state machines: name the states and transitions, keep state-dependent input and drawing in `case` statements, and act on transitions (edge detection) rather than on every update.

### Read
`Game#update`, `#click`, `#start`, `#start_round`, `#finish_round`, `Window#draw_hud`, `Window#sync_music`, `Mole#phase`, rule 7 in `docs/spec.md`.

### Concept
A **finite state machine** has a fixed set of states, one current state, and rules (transitions) for moving between them. The game screen is one:

```
:title --click--> :countdown --3 s--> :playing --60 s--> :game_over
                      ^                                       |
                      +------- click (after 1 s) or R --------+
```

The state is a single Symbol, `@state`. Every behavior that depends on it is a `case`:

- `Game#update`: countdown checks the timer; playing runs the round; title and game over do nothing.
- `Game#click`: title starts; game over restarts (after the lockout); playing whacks; countdown ignores the click entirely, which is how rule 1 ("clicks during the countdown do nothing") is implemented.
- `Window#draw_hud`: a different HUD for each state.

Transitions happen in exactly one place each (`start`, `start_round`, `finish_round`), and each one sets up everything the new state needs. `start` resets the score, moles, popups and both timers; that's why restarting is just calling `start` again.

**Why not booleans?** `@playing = true; @game_over = false; @counting_down = false` allows impossible combinations (playing *and* game over). One symbol can only be one thing.

**Moles are state machines too**, with derived states: `:rising → :up → :hiding → :gone`, or `→ :dropping → :gone` when whacked. Here the state isn't stored; `phase(now)` computes it from time (lesson 3.2).

**Acting on transitions.** Some things should happen once when the state *changes*, not every update while it *is* something. `Window#sync_music` remembers `@previous_state`; when the state changes to `:countdown` it starts the song, and when it changes to `:game_over` it stops it. Without the `return if @game.state == @previous_state` guard, the song would restart 60 times a second. This is called **edge detection**: reacting to the edge between states, not the level.

### Try it
1. Draw the screen state machine from memory, including what triggers each arrow. Check it against `game.rb`.
2. In `irb`, make a `Game` and drive it through every state with `click` and `update`, printing `state` each time.
3. Draw the mole state machine with the time boundaries for `up_ms: 1000`.

### Check yourself
1. Where in the code does a countdown click get ignored? Why is no special "ignore" code needed?
2. Why is `@state` one Symbol instead of several booleans?
3. What is edge detection, and what bug would `sync_music` have without it?

---

## Lesson 3.4: Entities and sprite animation

### Objectives
- **[G3.4]** Manage an entity's lifecycle: spawn into a collection, live through phases, and despawn by removing it, keeping the collection the single source of truth.
- **[G3.5]** Animate from a sprite sheet: load tiles, choose a frame index from elapsed time, play frames forward or in reverse, and scale pixel art without blurring.

### Read
`Game#spawn_mole`, `Game#update_round`, `Mole#frame`, `Window#load_tiles`, `Window#draw_moles`, `Window#draw_hammer`, `docs/spec.md` (Assets).

### Concept
**Entities** are the things in the world: moles and popups here. Their lifecycle:

1. **Spawn:** create and add to a collection (`moles << Mole.new(...)`, `popups << Popup.new(...)`).
2. **Live:** each update, the game asks them questions (`hittable?`, `gone?`); the window draws them.
3. **Despawn:** remove them when finished (`moles.reject! { |mole| mole.gone?(now) }`).

The collection *is* the world. Whatever is in `@game.moles` is drawn and can be hit; nothing else exists. That's why at most two moles can be up: `spawn_mole` only runs while `moles.size < Config::MAX_MOLES`. At game over the collections are emptied.

**Sprite sheets.** `mole-sheet.png` is four 36×36 pictures side by side. `Gosu::Image.load_tiles(path, 36, 36, retro: true)` cuts it into an array of four images, so `@moles[0]` is frame 0 and `@moles[3]` is the settled pose. Animation is picking which index to draw:

```ruby
when :rising then (now - @spawned_at) / Config::RISE_FRAME_MS        # 0, 1, 2 (80 ms each)
when :up then SETTLED_FRAME                                         # 3, held
when :hiding then 2 - ((now - @spawned_at - TRANSITION_MS - @up_ms) / Config::RISE_FRAME_MS)  # 2, 1, 0
when :dropping then 2 - ((now - @whacked_at) / Config::DROP_FRAME_MS)  # 2, 1, 0 (40 ms each: faster)
```

The pattern is always `elapsed / frame_duration` with integer division (phase 1). `2 - step` plays the same frames in reverse, so no extra art is needed for hiding or dropping. A looping animation would use `% frame_count` instead.

**Pixel art scaling.** The 36×36 sprites are drawn at `SCALE = 4` (144×144). Normally, scaling smooths (blurs) pixels. `retro: true` turns that off so every pixel becomes a crisp 4×4 block.

The game rules know frame *numbers* only. Images live in the window. `Mole#frame` is tested without loading a single picture.

### Try it
1. Open `assets/mole-sheet.png` in an image viewer and match each frame to a phase.
2. For a mole with `spawned_at: 0, up_ms: 600`, list the frame at every 40 ms from 0 to 1080.
3. Temporarily remove `retro: true`, run the game, and compare. Put it back.

### Check yourself
1. What three steps make up an entity's lifecycle, and where does each happen for moles?
2. How does the mole's hiding animation reuse the rising frames?
3. Why does `Mole#frame` return a number instead of an image?

---

## Lesson 3.5: Hit testing

### Objectives
- **[G3.6]** Implement point-in-rectangle hit testing in screen coordinates (origin top-left, y grows down), and explain why the hit box differs from the sprite box and why the hit point is offset from the cursor.

### Read
`Mole#contains?`, `#left`, `#top`, `Hammer.hit_point`, `Config` (the `HIT_*`, `SPRITE_ABOVE_HOLE` and `HAMMER_HEAD_OFFSET` constants), `Game#whack_at`, `test/whack_the_mole/hit_edge_cases_test.rb`.

### Concept
**Screen coordinates** start at the top-left corner `(0, 0)`. `x` grows to the right and `y` grows *down*. That's why a mole drawn *above* its hole has `top = hole.y - SPRITE_ABOVE_HOLE`.

**Point in rectangle** (axis-aligned bounding box, AABB): a point is inside if it's within the left/right edges *and* the top/bottom edges.

```ruby
def contains?(x, y)
  x.between?(left + HIT_LEFT, left + HIT_LEFT + HIT_WIDTH) &&
    y.between?(top + HIT_TOP, top + HIT_TOP + HIT_HEIGHT)
end
```

Two rectangles overlap (for collisions between moving things) if they overlap on both axes: `a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom`.

**Hit box vs sprite box.** The sprite is 144×144, but most of it is transparent. If clicks anywhere in that square counted, you'd hit moles by clicking empty grass beside them, which feels like a bug. So the hit box is a smaller rectangle around the mole's body: 48 wide and 76 tall, offset 40 and 16 pixels into the sprite. The commit "Enlarge mole hit box by 8px on each side" shows tuning after play-testing: slightly *generous* hit boxes feel fair to players.

**Hit point.** The hammer sprite is drawn centered on the mouse, but the part that hits is its head, up and to the left. `Hammer.hit_point` shifts the click by `HAMMER_HEAD_OFFSET = [-24, -28]` so the hit lands where the player *sees* the head. Players judge by what they see, not where the hidden cursor is.

**What a click hits.** `whack_at` finds the first mole whose box contains the point. No mole there: a miss (−1). A mole there but not `hittable?` (already whacked or hiding): nothing happens, neither hit nor miss.

### Try it
1. For a mole in a hole at `(320, 408)`, compute its hit box's four edges. Check with `mole.contains?` at each corner and one pixel outside.
2. A click at `(400, 380)`: where's the hit point? Does it hit that mole?
3. Read `hit_edge_cases_test.rb` and find the test for clicking a hiding mole.

### Check yourself
1. Why does `top` subtract from `hole.y` instead of adding?
2. Give two reasons the hit box is smaller than the sprite.
3. What does a click on a hiding mole score, and why is that kinder than a miss?

---

## Lesson 3.6: Spawning, randomness and difficulty

### Objectives
- **[G3.7]** Design spawn rules (free-slot selection, a concurrency cap, a spawn cadence) and use injected, seeded randomness so play is varied but tests and bug reports are reproducible.
- **[G3.8]** Shape difficulty over time with linear interpolation, keep tuning values in config, and judge a curve for fairness.

### Read
`Game#spawn_mole`, `Game#update_round`, `RoundTimer#elapsed_fraction`, `Config` (`MAX_MOLES`, `SPAWN_INTERVAL_MS`, `UP_MS_START`, `UP_MS_END`), rules 3 and 4 in `docs/spec.md`.

### Concept
**Spawn rules** are three questions:
1. *Where?* `Hole.grid - moles.map(&:hole)`: only free holes, so two moles never share one.
2. *How many?* `moles.size < MAX_MOLES`: never more than two at once, so the screen stays readable.
3. *When?* `now >= @next_spawn_at`, then `@next_spawn_at = now + SPAWN_INTERVAL_MS`: at most one spawn every 500 ms, so moles don't appear in bursts.

**Randomness, injected.** `free_holes.sample(random: @random)` picks the hole. In play, `@random` is `Random.new`, so every game differs. In tests it's `Random.new(1)`, so the same holes come up every time. A game can log its seed so a player's bug report ("the mole spawned under the hammer at 0:42") can be replayed exactly.

**Difficulty curve.** Over the round, moles stay up for less time. `elapsed_fraction(now)` goes from 0.0 at the start to 1.0 at the end, and **linear interpolation** (lerp) blends between two values:

```ruby
up_ms = UP_MS_START + ((UP_MS_END - UP_MS_START) * fraction)
# fraction 0.0 => 1200, 0.5 => 900, 1.0 => 600
```

`lerp(a, b, t) = a + (b - a) * t` is one of the most-used formulas in games: positions, colors, volumes, difficulty. Curves other than straight lines come from changing `t` first (for example `t * t` starts slow and speeds up).

**Tuning and fairness.** All the numbers live in `Config`, so a designer can change the feel without touching rules. A fair curve: starts easy enough to learn, ends hard but still possible (600 ms is roughly two to three times human reaction time), and changes smoothly so the player doesn't notice a jump. Play-test and adjust: the spec's numbers came from that.

### Try it
1. Compute `up_ms` at 0:45 left on the clock (what's `fraction`?).
2. Spawn moles with `Random.new(3)` in a `Game` twice and compare the holes. Then try `Random.new(4)`.
3. Change `UP_MS_END` to 300 and play a round. Is it still fair? Change it back.

### Check yourself
1. What three rules decide when and where a mole spawns?
2. Why does the game use `sample(random: @random)` instead of `sample`?
3. Write the lerp formula and give `up_ms` at 75% of the round.

---

## Lesson 3.7: Game feel

### Objectives
- **[G3.9]** Identify and design feedback ("juice") that makes actions feel good: animation, tweened popups with fading, sound with pitch variation, and protective rules like an input lockout.

### Read
`lib/whack_the_mole/popup.rb`, `Window#draw_popups`, `Window#play_thud`, `Hammer#frame`, `Game#click` (the game-over lockout), `Config` (`POPUP_*`, `MISS_SPEED`, `GAME_OVER_LOCKOUT_MS`).

### Concept
The rules of whack-a-mole fit on an index card. What makes it *fun* is feedback: every action gets an immediate, clear response. Count the responses to one click:

1. **The hammer swings** (3 frames, 50 ms each) on *every* click, so the game always acknowledges input.
2. **A thud plays.** Hit: normal pitch. Miss: the same sound slowed to 0.7 speed, lower and duller. One sound file, two meanings; the player learns the difference without reading anything.
3. **The mole drops** fast (40 ms frames versus 80 ms for rising): the hit feels forceful.
4. **A "+1" floats up and fades.**

The popup is a **tween**: a value moving from a start to an end over a duration. `progress(now)` is the 0.0 to 1.0 fraction of the 600 ms, clamped. The offset lerps from 0 to −40 pixels (up), and the alpha (opacity) from 255 to 0. The window packs alpha into the top byte of the color: `(alpha << 24) | (TEXT_COLOR & 0xffffff)`.

**Easing** makes tweens feel natural. Linear motion looks mechanical; real things slow down as they stop. An "ease out" curve such as `1 - (1 - t)**2` moves fast first and settles gently. You apply it to `t` before the lerp.

**Protective feel.** At the end of a round, players are still clicking frantically. Without `GAME_OVER_LOCKOUT_MS`, the click a few ms after time's up would instantly start a new round and they'd never see their score. The 1-second lockout ignores restart clicks just long enough. Likewise, a click on a hiding mole doesn't count as a miss: punishing a near-miss would feel unfair.

Good feedback is **immediate** (same frame), **proportional** (bigger results, bigger response), and **distinct** (hit and miss never look or sound alike).

### Try it
1. Change `POPUP_MS` to 2000 and `POPUP_RISE` to 120. Play. Then put them back. Which feels better and why?
2. Write `ease_out(t) = 1 - ((1 - t)**2)` and print it for `t` in `0, 0.25, 0.5, 0.75, 1`. Compare with linear.
3. Set `GAME_OVER_LOCKOUT_MS` to 0 and click wildly at the end of a round.

### Check yourself
1. List four pieces of feedback a single successful hit produces.
2. What does `Popup#progress` return 300 ms after it starts? What's the alpha then?
3. What problem does the game-over lockout solve?

---

## Lesson 3.8: Architecture and robustness

### Objectives
- **[G3.10]** Separate game rules from the engine (no `gosu` in rule files, constants in one config module), and explain how that enables headless tests and swapping the front end.
- **[G3.11]** Decide how a game should fail: degrade gracefully for optional things (sound, saves) and fail loudly and early for essential ones (sprites).

### Read
`CLAUDE.md` (Architecture), `lib/whack_the_mole.rb` vs `window.rb`, `Window#load_tiles`, `#load_audio`, `#play_thud`, `HighScore#save`, rules 8 and 9 in `docs/spec.md`.

### Concept
**Two layers.** The game is split in two:

- **Rules** (`game.rb`, `mole.rb`, `score.rb`, ...): plain Ruby. Know nothing about pixels, images, sounds or Gosu. Take time and randomness as inputs.
- **Front end** (`window.rb`): the only file that requires `gosu`. Turns Gosu's callbacks into calls on `Game`, and turns `Game`'s state into pictures and sounds.

The payoff:
- The whole test suite runs in well under a second with no window, because tests only load the rules.
- You could replace Gosu with a terminal front end, or a web page, without changing a rule. (Phase 4 adds a network front end of sorts.)
- Bugs are easier to find: "wrong score" means rules; "wrong picture" means window.

`Config` holds every tuning number and size in one place, so both layers agree (the window draws the hit box where the rules test it), and tuning never means hunting through logic.

**Failing well.** Not every failure deserves the same response:

| What fails | Response | Why |
|---|---|---|
| Music or thud file | `load_audio` returns `nil`; `@song&.play` skips it | The game is fully playable silently |
| High-score save | `warn`, keep playing | Losing one record isn't worth a crash |
| High-score file corrupt | Treat as 0 | The player can still play and set a new record |
| Sprite sheet | `abort "Could not load image: ..."` | Nothing can be drawn; a clear message now beats a confusing crash later |

Fail *early* (at startup, while loading) rather than mid-round, and fail with a message that says what to fix.

### Try it
1. Run `bundle exec rake test` and note the time. Why is it so fast?
2. Rename the thud mp3 temporarily, play, then restore it. Then do the same with `mole-sheet.png`. Compare.
3. Search `lib/` for `gosu`. Which files mention it?

### Check yourself
1. What would you lose if `mole.rb` required `gosu`?
2. Why is a missing sound handled differently from a missing sprite?
3. Name two benefits of having every tuning value in `Config`.

---

## Phase 3 project: the golden mole

Add a rare **golden mole** to the game.

**Rules (your spec):**
1. Each spawn has a 1-in-8 chance of being golden (`GOLDEN_CHANCE = 0.125` in config), decided with the game's injected `Random`.
2. A golden mole stays up for half the normal up-time at that point in the round.
3. Whacking it scores +3 and shows a "+3" popup. Misses and normal moles are unchanged. `hits` still counts it as one hit.
4. It's drawn with a gold tint (pass a color such as `0xff_ffd54f` to `Image#draw`; look up its parameters in the Gosu docs). No new art.
5. Its hit plays the thud at a higher pitch (speed around 1.3).
6. All existing tests still pass.

**How:**
1. Branch: `git switch -c phase-3-golden-mole`.
2. Change the rules first, test-first: golden chance (find a seed that makes the first spawn golden and one that doesn't), up-time, scoring, popup text. Keep `gosu` out of rule files.
3. Then the window: tint, popup text, pitch. Read state from the game; decide nothing there.
4. **Play-test log** in `practice/phase3/playtest.md`: play at least three rounds. Record your scores, how often you saw a golden mole, whether it felt fair, and one tuning change you tried (with the numbers) and what happened.
5. `rake test`, `rubocop` and the smoke launch pass.

The rubric is in the [phase 3 assessment](assessment.md), Part C.

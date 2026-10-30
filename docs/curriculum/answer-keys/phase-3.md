# Phase 3 answer key

Don't open this until you've written every Part A answer. An answer earns the point if it states the key idea, even in different words.

## Part A

### Q1
Input → update → draw (1 pt). `button_down`, `update`, `draw` (1 pt).

### Q2
Any two (1 pt each):
- Game rules now run at the *redraw* rate, which can differ from the update rate (and Gosu may skip draws), so play depends on the display.
- `draw` changes state, breaking "draw is read-only": what's drawn earlier in the same `draw` can be from before the update and later parts from after.
- `update` no longer advances the game, so anything relying on it (e.g. `sync_music` after the update) runs against stale state.

### Q3
The hammer would be drawn behind the moles, popups and HUD, so it disappears whenever it's over a mole: exactly where the player is aiming.

### Q4
1.2 s, 2.4 s, 0.5 s (1 pt each).

### Q5
(a) The window reads the clock once per callback (`Gosu.milliseconds`) and passes it as `now` to game methods; game code never reads the clock itself (1 pt). (b) Phase and frame are computed from `now - @spawned_at`, so they're correct at any frame rate, can't drift, and need no per-update bookkeeping; tests can ask about any time in any order (1 pt).

### Q6
**c.** Continuous motion with no start or end suits `dt`.

### Q7
`:countdown`, `:countdown`, `:playing`, `:game_over`, `:game_over`, `:countdown`. The click at 500 is ignored (no `when :countdown` in `click`); the round ends at 3000 + 60,000 = 63,000; at 63,500 only 500 ms of the 1,000 ms lockout has passed; at 64,000 it has.

### Q8
Edge detection: react when the state *changes*, not while it *is* something (1 pt). Without it, `play(true)` would run every update during the countdown, restarting the song about 60 times a second (or `stop` every update at game over) (1 pt).

### Q9
One symbol can only hold one state, so impossible combinations (playing and game over at once) can't exist; booleans would allow them.

### Q10
After the first two moles hide, no more moles appear for the rest of the round (1 pt): the gone moles stay in `moles`, so `moles.size < MAX_MOLES` is never true again. The gone moles would also still be drawn at frame 0 and still match `find` in `whack_at` (1 pt for the reason).

### Q11
`2`, `2`, `1`, `0` (half a point each) and `:gone` (1 pt). Drop frames are 40 ms; `DROP_MS` is 120, so at 1120 it's gone.

### Q12
(a) It turns off smoothing when scaling, so each 36×36 pixel becomes a crisp 4×4 block instead of a blur; the game draws pixel art at 4× (1 pt). (b) `(elapsed / 100) % 4` (1 pt). Any equivalent with 100 ms per frame is fine.

### Q13
(a) `left = 128 - 72 = 56`, `top = 216 - 80 = 136` (1 pt). (b) Left `56 + 40 = 96`, right `96 + 48 = 144`, top `136 + 16 = 152`, bottom `152 + 76 = 228` (1 pt). (c) Hit point `(150 - 24, 190 - 28) = (126, 162)`, inside the box: a hit (1 pt).

### Q14
(a) Most of the sprite is transparent; clicks on empty grass beside the mole shouldn't count. The box covers the mole's body (1 pt). (b) The hammer is drawn centered on the cursor but its head is up and to the left; the hit should land where the player sees the head (1 pt).

### Q15
Where: a random *free* hole; how many: fewer than `MAX_MOLES` (2); when: at most every `SPAWN_INTERVAL_MS` (500 ms) (1 pt). Injected so tests can use a seeded `Random` for repeatable spawns, and a round can be replayed from its seed (1 pt).

### Q16
(a) `0:30` → fraction 0.5 → `900`; `0:15` → fraction 0.75 → `750` (1 pt). (b) Ease *in*: use `fraction**2` (or any curve that starts flat and steepens) in place of `fraction` (1 pt).

### Q17
`progress = 0.25`, `offset = -10.0`, `alpha = 191` (1 pt each).

### Q18
Any three of: hammer swing, thud at normal pitch, fast drop animation, floating "+1" that fades, score update (1 pt). The lockout stops the frantic clicks right at the end of a round from immediately starting a new one before the player sees their score (1 pt).

### Q19
Any two (1 pt each):
- The rules can no longer be loaded or tested without Gosu (headless tests break, the architecture rule is broken).
- Tests can't control time: they'd have to wait real milliseconds, and results would vary run to run.
- One update would see several different "nows" (each call reads the clock), so a mole could be judged hittable and then gone within the same update.

### Q20
(a) `load_audio` returns `nil`; play continues silently: sound is optional. (b) `abort` with a message naming the file: the game can't be drawn. (c) `warn` and continue: losing one record isn't worth a crash. (d) Treated as best 0: corrupt data never crashes the game. (Half a point each.)

## Part B

Reference solution: [phase3_practical.rb](phase3_practical.rb). Notes:

- `overlaps?` uses strict `<`, so rectangles that only touch along an edge don't overlap; `contains?` uses `between?`, inclusive, like `Mole#contains?`.
- `frame_at` clamps negative elapsed times to 0, then either holds the last frame or wraps with `%`.
- `Flow` keeps its transitions in a frozen Hash: each state maps events to next states, and `fetch(event, state)` makes unknown events a no-op.
- `ScreenShake` is `Data` because nothing about it changes; the offset is computed from `now` and drawn from the injected `random`.

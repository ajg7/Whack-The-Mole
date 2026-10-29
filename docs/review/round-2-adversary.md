# Round 2 adversary review (commit 6c32abf)

Checks run by me: `bundle exec rake test` 61 runs, 0 failures; rubocop clean.

## Reviewer claims
- "No BLOCKING": CONFIRMED.
- Opaque bounds x 12-19, y 10-20 / 8-18 / 6-16 / 8-18: CONFIRMED by reading `to_blob` alpha of each tile (output: frame 0 y 10-20, 1 y 8-18, 2 y 6-16, 3 y 8-18, all x 12-19). Config box (x 12..20, y 6..21 sprite px) covers the union.
- "Slightly generous, not too strict": CONFIRMED. Box bottom is top+84, 4 screen px below the hole center; repro: `contains?(hole.x, hole.y+4)` true, `+5` false.
- Lockout, ignored double/hiding clicks, load_tiles rescue: CONFIRMED by reading code. Lockout repro (finished at 63000): click at 63999 stays `:game_over`, click at 64000 goes to `:countdown`. Boundary is inclusive as intended.
- MINOR 3 (nil result contract): CONFIRMED, harmless.
- MINOR 4 (hint text during lockout): CONFIRMED, cosmetic.

## New findings (all MINOR)
1. `window.rb:56-60` `restart` duplicates the swing that `Game#click` does and bypasses `Game`. A `Game#restart(now)` (swing + start) would keep the rule out of the window, which CLAUDE.md requires ("no game rules here").
2. Hit box is full height regardless of phase: a `:rising` mole at frame 0 (art only at sprite y 10-20) is already hittable by a click in the empty space above (sprite y 6-10, ~16 screen px). Repro: mole at age 0, `hittable?` true, frame 0. Small and arguably desirable leniency; no spec violation.
3. `load_tiles` handles only a missing PNG. Corrupt PNG raises RuntimeError too, so it is covered; the font and hole record need no files. Audio load failure is silently swallowed (`load_audio`), consistent with the spec's optional audio, but no message is printed.
4. Still unchanged from earlier rounds: no test covers `HighScore#load` for float like `5.0` through the Game; the unit test exists, so skip.

No frame-rate dependent logic found: all timings use `now` in ms. No double-hit path: `whacked?` blocks a second hit in the same frame. Negative score not reachable via the new changes (unchanged from round 1).

## Not checked
Real window/audio behavior (no GUI run), Windows `APPDATA` absent case beyond reading the code.

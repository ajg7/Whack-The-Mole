# Round 1 adversary (commit 6198f8c)

## Reviewer claims
1. Click on game_over restarts immediately (game.rb:28): CONFIRMED, spec-compliant (rule 7). MINOR is right.
2. Negative best loads as negative (high_score.rb:31): CONFIRMED. Repro: file `{"best":-5}` gives `b: -5`. MINOR is right.
3. Invalid UTF-8 raises unrescued EncodingError: WRONG for the tested case. File `\xff\xfe{"best":5}` loads as best 0 with no exception (JSON raises ParserError, already rescued). Unverified for other encodings; drop or demote to "not reproduced".
4. R key does not swing hammer: CONFIRMED, cosmetic.
5. Test gaps: plausible, not re-checked.

Also checked: missing/unwritable path returns best 0 and prints a warning without crashing (a directory at the path gave `d: 0` and a "Could not save" warn). Atomic save overwrote an existing file and left no `.tmp`. Asset PNGs exist, names match window.rb, `.gitignore` matches the spec.

## New findings
No BLOCKING.

MINOR
1. Double click on one mole costs a point. Repro (`ruby -Ilib -e` against Game): hit at t=3100 returns `:hit`, second click at t=3150 on the same dropping mole returns `:miss`, total 0. Spec rule 4 says a hit mole "can't be hit again" but does not say a second click is penalized. Either way, a double-click (common) nets zero. Decide in the spec; current behavior is defensible as "a click that hits no mole is -1".
2. A click on a mole in the `:hiding` phase is a miss (-1) although the mole is still visible. `hittable?` allows only rising/up. Spec says "up mole", so acceptable, but feels unfair for about 240 ms.
3. `Mole#contains?` uses the full 144x144 sprite rect including transparent pixels, so hits register on empty sprite padding. Cosmetic leniency, and rects of neighbouring holes do not overlap (cell 192 > 144).
4. `Game#click` in `:playing` is processed before `update` has noticed the round expired, so a click in that last frame can still score. Harmless; the score is recorded afterwards in `finish_round`.
5. `Window#load_tiles` is not guarded, so a missing PNG crashes at startup. The spec only requires audio to be skippable, so this is OK.

## Checked and fine
- All timing is elapsed ms passed in; no frame counts (hammer, popups, spawn, moles). A long frame only skips animation, with no logic drift.
- Timer at exactly zero: `expired?` is true and the state goes to game_over; the clock label shows 0:00. `start` resets score, moles, popups and both timers; the 60 s game_over then restart path works. Verified game_over at 63000 in a scripted run.
- Same hole twice in a row is allowed (the spec only forbids two moles at once). Randomness is injected. Hole, font and image creation happen once, not per frame. `ASSETS_DIR` is `__dir__`-relative.
- Not run by me: the full test suite, rubocop, the GUI. I relied on the reviewer's reported results for those.

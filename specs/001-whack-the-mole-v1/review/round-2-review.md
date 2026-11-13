# Round 2 review (commit 6c32abf)

Checks run: `bundle exec rake test` 61 runs, 0 failures; rubocop clean; smoke launch exit 124.

## BLOCKING
None.

## Hit area (32x60 on screen) assessment
- Spec conformance: spec rule 4/6 only says a click "on an up mole" hits and the hit point is the hammer head. It does not define the area, so opaque bounds do not conflict with it.
- Correctness: I measured the opaque pixels of `assets/mole-sheet.png`. Every frame spans x 12-19; y spans 10-20, 8-18, 6-16, 8-18. The config box (left 12, top 6, 8 wide, 15 tall, times 4) is the union of all frames, so it matches the art and is slightly generous (about 8 screen px above and below the settled pose). It is not too strict.
- Playability: the mole itself is only 8x11 art pixels (32x44 on screen), so a 32x60 box is as large as anything the player can see. With a 600-1200 ms up time and 2 moles it is harder than the old 144x144 box, but it is fair and matches what is drawn. The single-point hammer head offset (-24,-28) is unchanged, so the player has to put the hammer head on the mole; the 8 px grace is small but acceptable. Not too hard; no change required. If playtesting says otherwise, widening HIT_WIDTH is a one-constant change.

## MINOR
1. `lib/whack_the_mole/config.rb:23-26` and `mole.rb:56`: HIT_* values are derived from sprite pixels with no hint of where they come from. A short comment or naming them as sprite-pixel constants (`HIT_LEFT = 12`, then scaled in `Mole`) would help learners. At most a 1-line comment.
2. `mole.rb:56-57`: `contains?` repeats `left + HIT_LEFT` and `top + HIT_TOP` twice. Using ranges (`(l..l + w).cover?(x)`) would read cleaner.
3. `game.rb:84-85`: a click on a whacked or hiding mole returns `nil`, while other branches return `:hit`/`:miss`; `click` also returns nil for countdown/title. Works with `play_thud`, but the result contract is implicit. Could return `:ignored` for clarity.
4. `window.rb:143`: game-over text says "Click or press R to play again" during the 1 s lockout, when clicks do nothing. Optional: show the hint only after the lockout.
5. Item 7 (`window.rb:62-66`, load_tiles abort) has no test; acceptable since the window is untestable, and I confirmed Gosu raises `RuntimeError` for a missing file, so the rescue is correct.

Items 1-8 of round-2-fixes.md are otherwise implemented as asked, with tests (lockout boundary, negative/float best, hiding-click and double-click ignored without miss, hammer offset edges).

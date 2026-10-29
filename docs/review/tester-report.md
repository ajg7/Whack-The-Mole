# Tester report

Result (re-check after round 2): 67 runs, 0 failures; rubocop clean; smoke launch exit 124 (ok). BLOCKING bugs: none.

## Tests added (30, spec-driven, seeded Random, explicit ms, no window)
- test/whack_the_mole/hit_edge_cases_test.rb: hit on center and just inside edges, just outside = miss, empty hole and grass = -1, negative score, hits/misses separate, double hit in one frame, hiding mole unhittable, drop phase and popup, mole frame range, countdown numbers, hammer 3-frame swing, popup fade/expiry.
- test/whack_the_mole/round_edge_cases_test.rb: max 2 moles and no shared hole, 500 ms spawn, seeded determinism, huge and tiny time steps, 1200 ms up time at start and about 600 ms at end, clock labels, timer exactly zero, input after game over, restart resets state, state cleared at game over.
- test/whack_the_mole/high_score_edge_cases_test.rb: best persisted, lower score keeps best, missing file, corrupt/odd content (empty, truncated, garbage, [], null, wrong types, invalid bytes), path is a directory, directory creation with no leftover temp file, unwritable save warns and does not crash.

## Spec clauses covered
Rules 1 (timer, countdown clicks), 3, 4, 6 (hit-point offset, swing), 7 (flow, reset), 8, 10. Rule 2 only as geometry.

## Not testable without a window or assets
Rules 2 (colors, drawing, 4x draw), 5 (HUD placement), 6 (hidden cursor), 9 (music/thud/pitch; window-only), Assets, repo hygiene (.gitignore). The thud/music decisions live in window.rb with no seam.

## Notes (non-blocking)
- Clock label uses ceil, so it shows 1:00 for the first second of play (ms 3000-3999). Matches the spec's 1:00 -> 0:00 sequence.

## Bugs found
None.

## Round 2 re-check
Existing tests were not stale (all passed unchanged; lockout, hiding-mole-ignored and hammer-offset tests already matched). Superseded note: a click on an already-hit or hiding mole is now ignored (no score, no miss), asserted by tests.
Added test/whack_the_mole/round2_behavior_test.rb (6 tests): later click on a whacked mole ignored; game-over lockout boundary (999 ms ignored, 1000 ms restarts); lockout click leaves score unchanged; explicit start (R key path) bypasses lockout; hit box tighter than full 144 px sprite; negative/fractional/string stored best loads as 0.
Not testable: R-key hammer swing and the missing-PNG exit message (both in window.rb, no seam).
Bugs found: none. BLOCKING: none.

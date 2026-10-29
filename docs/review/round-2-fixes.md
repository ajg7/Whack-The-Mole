# Round 2 required items (user-approved fix of deferred minors)

Read docs/review/round-1-verdict.md for context on each. Fix all, keep changes small, add tests, keep spec rules intact (check docs/spec.md; if a fix conflicts with it, stop and say so).

1. Game-over click restarts instantly: ignore clicks for a short lockout (Config constant, ~1000 ms) after the round ends; R key still restarts immediately.
2. HighScore: a negative or non-integer stored best loads as 0 (high_score.rb:31).
3. R-key restart should swing the hammer like a click does.
4. Double click: a click on a mole that was already hit is ignored (no score change, no miss).
5. Click on a visible-but-hiding mole: not a hit, but not a miss either (ignored).
6. Hit area: use the mole's opaque bounds instead of the full 144x144 sprite rect (Config constant).
7. load_tiles: a missing PNG exits with a clear one-line message instead of a stack trace.
8. Fill the two test gaps noted in round-1-review.md.

Out of scope: assets/CREDITS.md (needs user-supplied sources).

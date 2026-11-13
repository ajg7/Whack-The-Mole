# Round 1 review (commit 6198f8c)

Checks run by me: `bundle exec rake test` 28 runs, 0 failures; `bundle exec rubocop` no offenses; smoke launch exit 124 (runs until killed).

## BLOCKING
None.

## MINOR
1. `lib/whack_the_mole/game.rb:28` and `window.rb:34`: a click on `:game_over` restarts immediately. A player still clicking when the timer hits 0 skips the game-over screen without seeing it. Suggested fix: ignore restart clicks for a short grace period (about 500 ms) after `finish_round`, or accept as-is since the spec allows it.
2. `lib/whack_the_mole/high_score.rb:31`: a stored negative integer (hand-edited file) loads as a negative best. Suggested fix: `[data['best'], 0].max`, or require `>= 0`.
3. `lib/whack_the_mole/high_score.rb:32`: invalid UTF-8 in a corrupt file can raise `EncodingError`, which is not rescued. Suggested fix: also rescue `EncodingError`.
4. `lib/whack_the_mole/window.rb:35`: the R-key restart does not swing the hammer, unlike a click. Cosmetic.
5. Test gaps: no test for `Game` hit detection with a hammer offset in the mole's rect edge, and none for the `HighScore` atomic save leaving no `.tmp` file. Window code is untested, which is acceptable under the architecture.

Architecture holds: Gosu is only in `window.rb`, time and `Random` are injected, and constants live in `config.rb`.

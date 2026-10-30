# Final answer key (Part A)

Don't open this until you've written every answer. An answer earns the point if it states the key idea, even in different words. Score each section separately as well as the total.

## Section R

### F1
`"1:30"`. `remaining_ms(500) = 90_000 - 500 = 89_500`; `seconds_left = (89_500 / 1000.0).ceil = 90`; `90.divmod(60) = [1, 30]`; `format` pads seconds to `30`. (1 pt result, 1 pt steps.)

### F2
`[216, 408, 600]` (1 pt). Three rows: `y = 120 + 192 × (row + 0.5)` for rows 0, 1, 2; every column in a row shares its `y`, and `uniq` drops the repeats (1 pt).

### F3
`0`: `return 0 unless @swung_at`, and `@swung_at` is `nil` (falsy) until the first swing.

### F4
`[1, 2, 1, 4]`; `[1, 2, 3, 4]`; `ArgumentError` (missing keyword `scale`); `ArgumentError` (wrong number of arguments: `y` is required). Half a point each.

### F5
It raises `NoMethodError: undefined method 'reject' for nil` (1 pt). The assignment makes `moles` a local variable for the whole rest of the method, so the right-hand `moles` reads that new local (still `nil`) instead of calling the reader; even if it worked, it would only change a local, never the game's `@moles` (1 pt).

### F6
The status is a fixed set of identifiers chosen in code: symbols (1 pt). `top` returns data parsed from JSON, which only has string keys (1 pt).

## Section O

### F7
Any two of: `hit!`/`miss!` can't change frozen fields; `Game` would have to replace its score with `with(...)` on every click; anything holding the old score object sees stale numbers (1 pt). `Score` changes over time and has an identity across the round; `Data` is for values that never change (1 pt).

### F8
It lets any code replace the client's collaborator at any time, widening the public interface for no gain; injection through `initialize` already lets tests pass a fake, and the client stays in charge of its own state.

### F9
`@leaderboard = LeaderboardClient.new(base_url: ENV.fetch('LEADERBOARD_URL', 'http://localhost:3000'))` (1 pt). The window is where real collaborators are wired up (like `Random.new` and `HighScore.new`); code that receives the client can be tested with a fake, and the URL decision lives in one place (1 pt).

### F10
Any three (1 pt each):
- `eval` on file contents runs arbitrary code; use `JSON.parse`.
- Bare `rescue` hides bugs; rescue `JSON::ParserError, SystemCallError`.
- JSON built by interpolation breaks (or is corrupted) when the name contains `"` or `\`; use `JSON.generate(season: name)`.
- Not an atomic write; write a temp file and `File.rename`.
- No `mkdir_p`, so the first save fails if the folder doesn't exist; no handling of save errors.
- No shape check on the loaded data.

### F11
The thing under test *is* real concurrency: "returns at once while the request is still running" can only be shown with real time (1 pt). Game logic takes time as an input, so its tests can use any time instantly and exactly; using real time there would be slow and flaky (1 pt).

### F12
Write a failing test through the public interface that reproduces it (seeded `Random` that spawns a golden mole, whack it at a known time, assert +3) and watch it fail; find and fix the cause with the smallest change; run the full suite; refactor if needed; commit test and fix together. (2 pts for red → green → full suite; 1 pt if the test isn't written first.)

## Section G

### F13
The submission (or `top` fetch) runs on the main thread, so `update` waits for the network and the loop stops (1 pt). Move it to a background thread that reports through a `Thread::Queue`, and drain the queue without blocking in `update` (1 pt).

### F14
(a) No change: up-time is computed from timestamps (1 pt). (b) Spawns can only happen on an update, so each can be up to ~33 ms late, and the 500 ms cadence drifts slightly later (1 pt). (c) The swing still lasts 150 ms but each 50 ms frame is shown for one or two draws, so it looks a bit choppier (1 pt).

### F15
(a) `update`, `click` (and `Window#draw_hud`) need a `:paused` branch; something must handle the P key to enter and leave (1 pt). (b) The round timer, mole and popup timestamps keep aging: unpausing could end the round instantly and every mole would have vanished (1 pt). (c) Feed the game a *game clock* that stops while paused (e.g. the window passes `now - total_paused_ms`), or shift every stored timestamp by the pause length on resume (1 pt).

### F16
`left = 512 - 72 = 440`, `top = 600 - 80 = 520`; box x `480..528`, y `536..612`; hit point `(516, 572)`: inside, a hit. (1 pt box, 1 pt hit point and conclusion.)

### F17
(a) `1/8 × 1/8 = 1/64` (about 1.6%) (1 pt). (b) A "pity" rule: count spawns since the last golden mole and force a golden one after N (or raise the chance each spawn), keeping the injected `Random` for everything else. Test with a seed that would produce no golden mole and assert one appears by spawn N (1 pt).

### F18
Any answer that's immediate (as soon as the result arrives), proportional (bigger for a high rank) and distinct (doesn't look or sound like a hit or miss), e.g. the rank text pops in with a short chime.

## Section W

### F19
The body has none of the expected field names (e.g. `name` instead of `player_name`), or isn't sent as JSON (missing `Content-Type: application/json`), so there's no `score` hash even after Rails' parameter wrapping. A missing `score` wrapper alone is *not* enough: wrapping fixes that.

### F20
The game's limit is for the player (immediate feedback, fits on screen) (1 pt). The server can't trust any client; anyone can post directly, so the model must enforce it too (1 pt).

### F21
```ruby
PERIODS = { 'today' => -> { Time.current.beginning_of_day }, 'week' => -> { 1.week.ago } }.freeze

def index
  start = PERIODS[params[:period]]&.call
  @scores = (start ? Score.since(start) : Score).top
  ...
end
```
Any equivalent that maps known values and treats everything else as all-time. (1 pt correct scopes, 1 pt safe handling of unknown values.)

### F22
Fixtures: one score created today and one with `created_at: <%= 1.day.ago.beginning_of_day %>` (yesterday) (1 pt). Integration test: `get scores_url(format: :json, period: 'today')`, assert 200, assert today's name is in `parsed_body.pluck('player_name')` and yesterday's isn't (1 pt).

### F23
Saved as an ordinary string: Active Record uses bound parameters, so it's never run as SQL (1 pt). Shown as text: ERB escapes output. The two practices: hash/placeholder queries (no string SQL) and escaped output (1 pt).

### F24
The controller (period handling) and `app/views/scores/index.html.erb` (links and highlight), plus tests (1 pt). No new route: `period` is a query parameter on the existing `GET /scores` route, e.g. `scores_path(period: 'today')` (1 pt).

## Section I

### F25
(a) Models (1 pt) (b) Views (c) Controllers (1 pt for both). Any one reason: rules can be tested without the front end; each part changes for one reason; the front end can be swapped; bugs are easier to locate (1 pt).

### F26
In `update`, with a non-blocking check (`pop(true)` when not empty), storing the result in game or window state (1 pt). `draw` must be read-only: taking from the queue changes state there, and if draws are skipped the result is picked up late or depends on the display (1 pt).

# Whack-The-Mole v1: implementation plan (Eevee)

## 1. Context

`docs/spec.md` describes v1: a 60-second whack-a-mole round on a 3x3 grid, built in Ruby with Gosu. The repo has no code yet. It holds only `assets/` (two `.aseprite` sheets and two MP3s), `docs/spec.md`, `CLAUDE.md` and `.claude/`. This code becomes Ruby teaching material later, so every choice below favors the plain, readable version: small classes named after game concepts, keyword arguments, `Data.define` for value objects, and Enumerable over index loops.

Facts checked locally while planning:
- `assets/mole-Sheet.aseprite` has one frame on a 144x36 canvas, and `assets/Hammer-Sheet.aseprite` has one frame on a 108x36 canvas (read from the file headers). That means the spec's `--save-as` command gives one PNG strip each, which is what `load_tiles(…, 36, 36)` needs. (`--save-as` on a multi-frame file would write one file per frame instead.)
- `assets/CREDITS.md` does **not** exist yet, although the spec lists it. The coder creates it (see the open questions).
- Ruby is not installed. ffmpeg is not installed, and it isn't needed (see 6.2).

## 2. Approach (the recommendation)

- **Gosu 1.4.6** (the latest stable release), pinned `~> 1.4`. Skip the 2.0.0.pre prereleases.
- One `Gosu::Window` subclass (`Window`) is the only code that touches Gosu. Everything else is plain Ruby under `WhackTheMole::` and can be tested without a window.
- **Time model:** the window passes `now = Gosu.milliseconds` into every game call (`update(now)`, `click(x, y, now:)`). Game objects store timestamps (for example `spawned_at`) and work out their state from `now`. There are no frame counters and no per-frame deltas, so behavior doesn't depend on the frame rate, and tests can step time by passing literal numbers.
- **Randomness:** `Game.new(random: Random.new)`. Tests pass `Random.new(1)`.
- **States** are four symbols on `Game` (`:title`, `:countdown`, `:playing`, `:game_over`) with a small `case` per state. One class per state would be overkill for v1.
- **Sound events:** `Game#click` returns `:hit`, `:miss`, or `nil`, and the window plays the thud based on that. The window starts and stops the music when it sees `game.state` change. Game rules never know audio exists.
- **High score:** `HighScore` reads and writes `{"best": n}` at `File.join(ENV.fetch('APPDATA') { Dir.home }, 'WhackTheMole', 'highscore.json')`, using `JSON.parse` only and an atomic rename. The path is injected, so tests use `Dir.mktmpdir`.
- **MP3s are used as-is.** No OGG conversion (evidence in 6.2).

## 3. Files and public API

```
Gemfile, Gemfile.lock (generated, committed), Rakefile, .rubocop.yml, .gitignore
bin/whack_the_mole
lib/whack_the_mole.rb                 # requires every plain-Ruby file below (no gosu)
lib/whack_the_mole/config.rb          # module Config: all constants
lib/whack_the_mole/hole.rb            # Hole = Data.define(:x, :y) + Hole.grid
lib/whack_the_mole/mole.rb
lib/whack_the_mole/score.rb
lib/whack_the_mole/round_timer.rb
lib/whack_the_mole/hammer.rb
lib/whack_the_mole/popup.rb           # Popup = Data.define(:x, :y, :started_at)
lib/whack_the_mole/high_score.rb
lib/whack_the_mole/game.rb
lib/whack_the_mole/window.rb          # the only file with require 'gosu'
assets/mole-sheet.png, assets/hammer-sheet.png (exported), assets/CREDITS.md
test/test_helper.rb + test/whack_the_mole/<name>_test.rb mirroring lib/
```

### `Config` (module of constants)
`WIDTH = 640`, `HEIGHT = 720`, `GRASS_COLOR = 0xff_4caf50`, `HOLE_COLOR = 0xff_4e342e`, `TEXT_COLOR`, `GRID_COLS = 3`, `GRID_ROWS = 3`, `CELL_SIZE = 192`, `GRID_TOP = 120`, `SPRITE_SIZE = 36`, `SCALE = 4`, `HOLE_WIDTH = 150`, `HOLE_HEIGHT = 50`, `ROUND_MS = 60_000`, `COUNTDOWN_MS = 3_000`, `MAX_MOLES = 2`, `SPAWN_INTERVAL_MS = 500`, `UP_MS_START = 1200`, `UP_MS_END = 600`, `RISE_FRAME_MS = 80`, `DROP_FRAME_MS = 40`, `SWING_FRAME_MS = 50`, `HAMMER_HEAD_OFFSET = [x, y]` (set after looking at the exported PNG, in screen pixels at 4x), `POPUP_MS = 600`, `POPUP_RISE = 40`, `MISS_SPEED = 0.7`, `ASSETS_DIR = File.expand_path('../../assets', __dir__)`. All are frozen literals. A grid that grows later only changes `GRID_COLS`/`GRID_ROWS`.

### `Hole`
`Hole = Data.define(:x, :y)` (the hole's center). `Hole.grid(cols:, rows:)` returns the 9 holes, built with `product`/`map` from the config.

### `Mole`
`Mole.new(hole:, spawned_at:, up_ms:)`
- `#phase(now)` returns `:rising`, `:up`, `:hiding`, `:dropping`, or `:gone`.
- `#frame(now)` follows the phase: rising shows 0, 1, 2 at `RISE_FRAME_MS` each. `:up` shows frame 3 (it "settles back" from the peak). `:hiding` shows 2, 1, 0 at `RISE_FRAME_MS`. `:dropping` (after a hit) shows 2, 1, 0 at `DROP_FRAME_MS`.
- `#hittable?(now)` is true in `:rising` or `:up`, and only if the mole hasn't been whacked.
- `#whack(now)` records `whacked_at`.
- `#contains?(x, y)` checks whether the point is inside the 144x144 sprite rect drawn over the hole.
- `#gone?(now)`.
- `attr_reader :hole`. Nothing outside the class mutates a mole except through `whack`.

### `Score`
`#hit!`, `#miss!`, `attr_reader :hits, :misses`, `#total` (= `hits - misses`, so it can go negative).

### `RoundTimer`
`RoundTimer.new(started_at:, duration_ms:)`, with `#remaining_ms(now)` (clamped at 0), `#expired?(now)`, `#elapsed_fraction(now)` (0.0 to 1.0), and `#clock_label(now)`, which returns `"m:ss"` with remaining seconds rounded up (`1:00` at the start, `0:59` after 1 s, `0:00` at expiry). The countdown reuses this class, with `COUNTDOWN_MS` and `#seconds_left(now)` returning 3, 2, 1.

### `Hammer`
`#swing(now)`, `#frame(now)` (0, 1, 2 over `SWING_FRAME_MS` each, then 0 at rest), and `Hammer.hit_point(x, y)` (the mouse position plus `HAMMER_HEAD_OFFSET`).

### `Popup`
`Data.define(:x, :y, :started_at)`, with `#offset(now)` and `#alpha(now)`, and `#expired?(now)` after `POPUP_MS`.

### `HighScore`
`HighScore.new(path: HighScore.default_path)`, with `#best` and `#record(score)` (saves only when `score > best`, and returns the best).
- **Load:** `JSON.parse(File.read(path))`. If the result is a Hash whose `"best"` is an Integer, that is the best. Anything else counts as 0. Rescue `Errno::ENOENT`, `JSON::ParserError` and `SystemCallError`.
- **Save:** `FileUtils.mkdir_p(File.dirname(path))`, `File.write("#{path}.tmp", JSON.generate(best: n))`, then `File.rename(tmp, path)`. Ruby's Windows `rename` uses `MoveFileExW(…, MOVEFILE_REPLACE_EXISTING)`, so the rename overwrites safely. If the write fails, the failure is rescued (`SystemCallError`) and reported with `warn`. Losing a high-score save must never crash the game.
- **`default_path`** reads `ENV.fetch('APPDATA') { Dir.home }`, which falls back to the home directory if `APPDATA` is not set.

### `Game` (the rules)
`Game.new(random:, high_score:)`
- `attr_reader :state, :score, :moles, :popups, :hammer, :best`
- `#update(now)`
  - `:countdown` changes to `:playing` (and starts the `RoundTimer`) once the countdown expires.
  - `:playing` drops moles and popups that are gone, then spawns. A new mole appears when `moles.size < MAX_MOLES` and `now >= next_spawn_at`, in `free_holes.sample(random:)`, with `up_ms` interpolated from `UP_MS_START` to `UP_MS_END` by `elapsed_fraction`. When the round expires, the state changes to `:game_over`, the moles are cleared, and `@best = high_score.record(score.total)`.
- `#click(x, y, now:)` always calls `hammer.swing(now)`. In `:title` it starts the countdown. In `:countdown` it does nothing. In `:playing` it finds the hittable mole containing `Hammer.hit_point(x, y)`. On a hit it whacks the mole, calls `score.hit!`, adds a popup, and returns `:hit`. Otherwise it calls `score.miss!` and returns `:miss`. In `:game_over` it restarts.
- `#restart(now)` builds a fresh `Score`, empties the moles and popups, and starts the countdown (rule 7). The window calls it on R in `:game_over`.
- `#clock_label(now)`, `#countdown_number(now)` (for the HUD).

### `Window < Gosu::Window`
- **`initialize`**: `super(Config::WIDTH, Config::HEIGHT)`, sets the caption, and loads everything once:
  - `Gosu::Image.load_tiles(path, 36, 36, retro: true)` for the mole and the hammer
  - `Gosu::Font.new(32)`
  - a hole oval recorded once with `Gosu.record(w, h) { triangle fan via draw_triangle }`, because Gosu has no ellipse primitive
  - `@song` and `@thud`, through `load_audio { Gosu::Song.new(path) }`, which returns `nil` on `RuntimeError` (SWIG maps Gosu's C++ `std::exception` to `RuntimeError`) or when the file is missing
- **`needs_cursor?`** returns `false` (rule 6).
- **`update`** calls `game.update(Gosu.milliseconds)`, then `sync_music`: `@song&.play(true)` when the state enters `:countdown`, and `@song&.stop` when it enters `:game_over`.
- **`button_down(id)`**: `Gosu::MS_LEFT` calls `play_thud(game.click(mouse_x, mouse_y, now: Gosu.milliseconds))`, where `:hit` gives `@thud&.play(1.0, 1.0)` and `:miss` gives `@thud&.play(1.0, Config::MISS_SPEED)`. `Gosu::KB_R` restarts on game over. For any other button, call `super`.
- **`draw`** draws in order: grass `draw_rect`, holes, moles (`tiles[mole.frame(now)].draw(x, y, z, SCALE, SCALE)`), popups, HUD (clock top-left, score top-right with `draw_text_rel(…, 1.0, 0.0)`, countdown centered), title and game-over text, and the hammer last at the mouse position.

### `bin/whack_the_mole`
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/whack_the_mole/window'
WhackTheMole::Window.new.show
```
`window.rb` does `require 'gosu'` and `require_relative '../whack_the_mole'`.

## 4. Ordered implementation steps

1. **Tooling.** Create:
   - **`Gemfile`**:
     ```ruby
     # frozen_string_literal: true

     source 'https://rubygems.org'
     ruby '>= 3.3'

     gem 'gosu', '~> 1.4'

     group :development, :test do
       gem 'minitest', '~> 6.0'
       gem 'rake', '~> 13.0'
       gem 'rubocop', '~> 1.92', require: false
       gem 'rubocop-minitest', '~> 0.41', require: false
     end
     ```
     `rubocop-minitest` stays because Minitest 6 removed `assert_equal nil` and the cop catches it. That makes four dev gems plus Gosu.
   - **`Rakefile`**:
     ```ruby
     # frozen_string_literal: true

     require 'rake/testtask'

     Rake::TestTask.new(:test) do |t|
       t.libs << 'test'
       t.pattern = 'test/**/*_test.rb'
     end

     task default: :test
     ```
     (`lib` is already on the default libs. The default pattern `test/test*.rb` would miss `*_test.rb` files, which is why the pattern is set.)
   - **`.rubocop.yml`**:
     ```yaml
     plugins:
       - rubocop-minitest
     AllCops:
       TargetRubyVersion: 3.3
       NewCops: enable
       Exclude:
         - 'vendor/**/*'
     Style/Documentation:
       Enabled: false
     ```
     Rubocop defaults otherwise. That means single-quoted strings and `frozen_string_literal` on every file, including `bin/whack_the_mole`, which rubocop picks up through its ruby shebang. `Style/Documentation` is off because CLAUDE.md forbids comments that aren't needed.
   - **`.gitignore`**, exactly the spec list: `.bundle/`, `vendor/bundle/`, `tmp/`, `coverage/`, `*.gem`, `.rubocop-*`, `*.log`, `.DS_Store`, `Thumbs.db`, `.vscode/`, `.idea/`. Don't ignore `Gemfile.lock`.
   - Run `bundle install` and commit `Gemfile.lock`. It will list the `x64-mingw-ucrt` platform, which is fine for a Windows-only v1.
2. **Assets.** Export, then check each PNG's size (it must be 144x36 and 108x36), then view each PNG to choose `HAMMER_HEAD_OFFSET`:
   ```
   "C:/Program Files/Aseprite/Aseprite.exe" -b assets/mole-Sheet.aseprite --save-as assets/mole-sheet.png
   "C:/Program Files/Aseprite/Aseprite.exe" -b assets/Hammer-Sheet.aseprite --save-as assets/hammer-sheet.png
   ```
   Write `assets/CREDITS.md`, and commit the sources and the PNGs.
3. **`config.rb`, `hole.rb`, `score.rb`, `round_timer.rb`**, each with its tests.
4. **`mole.rb`** and its tests (phases, frames, `hittable?`, whack).
5. **`hammer.rb`, `popup.rb`** and tests.
6. **`high_score.rb`** and tests (tmpdir).
7. **`game.rb`** and tests: state machine, spawning, scoring, restart.
8. **`lib/whack_the_mole.rb`, `window.rb`, `bin/whack_the_mole`.** Then run the smoke launch and a manual play-through.
9. Run `bundle exec rubocop -a`, then `bundle exec rake test`, then commit.

## 5. Security and scalability notes
- Don't use `eval`, YAML, or `Marshal`. The save file is read only with `JSON.parse` and is shape-checked: it must be a Hash with an Integer `"best"`.
- Asset paths are always `File.join(Config::ASSETS_DIR, 'name')` and never built from user input. The save path comes from `APPDATA` plus constants.
- The save is atomic (temp file, then rename). A missing or corrupt file counts as best = 0, and a failed write is reported with `warn` and never raises.
- No allocation per frame: images, the font, the oval and audio load once in `initialize`. Moles and popups are created only on spawn and on hit.
- Timing uses only timestamps from `Gosu.milliseconds`. `Gosu.milliseconds` wraps "for long-running games", which is not a concern for 60-second rounds.
- The grid size, durations, and the start and end up-times all live in `Config`.

## 6. Risks and open questions

### 6.1 Installing Gosu on Windows (checked by unpacking `gosu-1.4.6.gem`)
- Every Gosu release on RubyGems is `platform: ruby`, so there is **no prebuilt Windows gem**. The C++ extension is **compiled** at install time, which is why the DevKit (MSYS2 + MinGW toolchain, `ridk install` option 3) is required.
- `ext/gosu/extconf.rb`, Windows branch: "Use the bundled versions of SDL 2 and open_al". It links `-lgdi32 -lwinmm -ldwmapi -lOpenGL32 -lSDL2` against `dependencies/SDL/lib/x64`, and the gem ships `lib64/SDL2.dll`. **No MSYS2 packages are needed beyond the toolchain.**
- **Ruby 3.4 is unverified.** I found no reported issues and no confirmations. The wrapper is SWIG 4.1.1 and uses no C APIs removed in 3.4 that I could find, so it likely compiles, perhaps with deprecation warnings. **Recommendation: RubyInstaller Ruby+Devkit 3.3.x** (the lowest risk). Fall back to 3.3 if 3.4 fails to build.
- The Gosu wiki's Windows page links its "Installer" to a non-official GitHub release (`bonkonauts/cors-anywhere`). Ignore that link and use rubyinstaller.org.

### 6.2 MP3 playback
Supported on Windows. On every platform except iOS, Gosu decodes audio through the bundled SDL_sound (`src/AudioFileSDLSound.cpp`, `#ifndef GOSU_IS_IPHONE`). `SDL_sound_internal.h` sets `SOUND_SUPPORTS_MP3 1` through `dr_mp3`, and OGG Vorbis is also enabled. **No OGG conversion.** If a file fails at runtime anyway, the rule-9 skip handles it silently.

### 6.3 Open questions for the user
1. **Frame 3 of the mole.** The plan shows frame 3 as the settled "up" pose, then hides with the reverse of 2, 1, 0. Is that right, or is frame 3 meant to be part of the hide?
2. **Spawn cadence** isn't in the spec. The plan uses `SPAWN_INTERVAL_MS = 500` between spawns while fewer than 2 moles are up.
3. **`assets/CREDITS.md` is missing.** The filenames suggest Pixabay uploads ("dcuttermusic", "freesound_community"), but I couldn't confirm the source URLs or licenses. The coder can write a CREDITS file from the filenames, and the user should add the URLs.
4. **The hit point** is the mouse position plus `HAMMER_HEAD_OFFSET`. The value is a guess until the PNG has been viewed.
5. **Window size** of 640x720 is the plan's choice. The spec doesn't set one.

Skipped on purpose (not in the spec): an Escape-to-quit key, pausing, and a settings or volume UI.

## 7. Research sources
- Gosu versions: https://rubygems.org/api/v1/versions/gosu.json (1.4.6, 2023-05-20, is the latest stable. 2.0.0.pre8, 2024-02-25, is a prerelease. All are `platform: ruby`.)
- Gem contents: https://rubygems.org/downloads/gosu-1.4.6.gem (files `ext/gosu/extconf.rb`, `lib64/SDL2.dll`, `src/AudioFileSDLSound.cpp`, `dependencies/SDL_sound/SDL_sound_internal.h`, `rdoc/gosu.rb`, `src/RubyGosu.cxx`)
- API, from the gem's `rdoc/gosu.rb` (the same content as https://rubydoc.info/gems/gosu):
  - `Sample#play(volume=1, speed=1, looping=false)`
  - `Song#play(looping=false)`, `Song#stop`
  - `Window#needs_cursor?` ("base class implementation returns true")
  - `Gosu.milliseconds` (an Integer, which can wrap)
  - `Image.load_tiles(source, tile_width, tile_height, options = {})` with `:retro`
  - `Window#mouse_x`/`mouse_y` (accessors that return Floats)
  - `Font#draw_text_rel`, `Gosu.record`, `Gosu.draw_triangle`/`draw_rect`
- Windows install guide: https://github.com/gosu/gosu/wiki/Getting-Started-on-Windows ("install the DevKit", then `gem install gosu`)
- Ruby's Windows rename: https://raw.githubusercontent.com/ruby/ruby/v3_3_0/win32/win32.c (`MoveFileExW(... MOVEFILE_REPLACE_EXISTING ...)`)
- Minitest 6 breaking changes: https://raw.githubusercontent.com/minitest/minitest/master/History.rdoc (6.0.0, 2025-12-17: Ruby 3.2+, mock extracted, no `assert_equal nil`)
- Dev gem versions from the RubyGems API on 2026-10-28: minitest 6.0.6, rake 13.4.2, rubocop 1.92.1, rubocop-minitest 0.41.0
- Aseprite CLI: https://www.aseprite.org/docs/cli/ (`--save-as` writes one file per frame for multi-frame sprites, and `--sheet --sheet-type horizontal` packs frames into a sheet; it isn't needed here because both files have one frame)
- RubyInstaller 3.4 Devkit builds: https://www.wingetly.io/apps/ruby-installer-team/ruby-with-dev-kit-3-4 (unofficial mirror listing; use rubyinstaller.org to download)

## 8. Test plan (maps to spec clauses)
All tests use `Minitest::Test`, `Random.new(1)`, and literal `now` values. `test_helper.rb` requires `minitest/autorun` and `whack_the_mole` and never Gosu.

| Spec | Test |
|---|---|
| R1 round | `RoundTimer#clock_label`: `1:00` at 0 ms, `1:00` at 1 ms, `0:59` at 1000 ms, `0:00` at 60000 ms and beyond. The countdown shows 3, 2, 1. The game changes to `:playing` exactly at 3000 ms. |
| R1 countdown clicks | `click` during `:countdown` returns `nil`, and the score, hits and misses don't change. |
| R2 field | `Hole.grid` returns 9 distinct holes. Every constant exists in `Config` (smoke). |
| R3 moles | Over many updates, `moles.size <= 2` always holds and the holes are unique. Seeded spawns are deterministic. `up_ms` is 1200 at the start and 600 at the end, and in between halfway. Mole frames follow 0→1→2, then the `:up` frame, then the hide frames, then gone. |
| R4 scoring | A hit gives +1 and the hit count goes up. A mole stops being hittable once whacked: a second click on it is a miss. A click on grass or an empty hole gives -1. An escaped mole leaves the score unchanged. The score can go below 0. A hit adds a `Popup` that expires after `POPUP_MS`. |
| R5 HUD | The game exposes the clock label and score in `:countdown` and `:playing` (state-level check). |
| R6 hammer | `Hammer#frame` goes 0→1→2, then rests. `Hammer.hit_point` applies the offset. Clicks are tested against the hit point, not the raw mouse position. |
| R7 screens | title → (click) countdown → playing → (timer) game_over. A click or `restart` from game_over resets the score, hits, misses, timer and moles. |
| R8 high score | A missing file gives 0. Corrupt JSON, `[]`, `{"best":"x"}` or `5` give 0. `record` saves only a higher score. The file round-trips. No `.tmp` file is left behind. A parent directory that doesn't exist is created. |
| R9 sound | `click` returns `:hit` or `:miss` for scored clicks and `nil` otherwise. The window's sound mapping is checked manually during the play-through. |
| R10 timing | The same `now` sequence with different step sizes (16 ms vs 33 ms) ends in the same state. |

## 9. Verification
1. `bundle exec rake test` passes.
2. `bundle exec rubocop` reports no offenses.
3. `timeout 5 bundle exec ruby bin/whack_the_mole` exits with 124.
4. Manual check:
   - the cursor is hidden and the hammer swings
   - moles rise and hide
   - a hit plays the thud at normal pitch, and a miss plays it lower
   - the music loops and stops at game over
   - the best score persists across launches in `%APPDATA%\WhackTheMole\highscore.json`
   - deleting or corrupting that file doesn't crash the game

## 10. Hand-off: first steps for the coder (Flareon)
1. Confirm `ruby -v` (3.3+, a RubyInstaller DevKit build) and `ridk version`. If `gem install gosu` fails on 3.4, report it and switch to 3.3.
2. Create `Gemfile`, `Rakefile`, `.rubocop.yml` and `.gitignore` as in step 1. Run `bundle install` and commit `Gemfile.lock`.
3. Export both sheets with the Aseprite CLI, verify the 144x36 and 108x36 PNG sizes, view the hammer PNG to set `HAMMER_HEAD_OFFSET`, and write `assets/CREDITS.md`.
4. Build the classes in the order of section 4, writing each class's test with it.
5. Run the verification steps, then commit. Don't push.

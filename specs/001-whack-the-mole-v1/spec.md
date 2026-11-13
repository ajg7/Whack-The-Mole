# Whack-The-Mole v1 spec

A 2D whack-a-mole desktop game in Ruby using Gosu. The player has 60 seconds to whack as many moles as possible.

## Assets
- `assets/mole-Sheet.aseprite`: 4 frames of 36×36 in one row, transparent background. Frames 0→2 are the mole rising; frame 3 settles back.
- `assets/Hammer-Sheet.aseprite`: 3 frames of 36×36, transparent background. A 3-step swing.
- Gosu can't load `.aseprite`, so export each sheet to PNG with `"C:/Program Files/Aseprite/Aseprite.exe" -b <in>.aseprite --save-as <out>.png` and load it with `Gosu::Image.load_tiles(path, 36, 36, retro: true)`. Commit the sources and the PNGs.
- `assets/dcuttermusic-whack-a-mole-178509.mp3`: background music.
- `assets/freesound_community-thud2-97615.mp3`: thud sound effect.
- `assets/CREDITS.md` lists the audio sources.

## Rules
1. **Round.** A round lasts 60 seconds, shown top-left as `m:ss` (`1:00`, `0:59`, …, `0:00`). It starts after a 3-2-1 countdown shown in the center. Clicks during the countdown do nothing and are not scored.
2. **Field.** A standard grass green background (one constant in `config.rb`). A 3×3 grid of holes, each drawn as a dark brown oval. Sprites are drawn at 4× scale. The window is 640×720 (the grid plus a top HUD bar).
3. **Moles.** At most 2 moles are up at once, never two in the same hole. Moles spawn at random free holes using an injected `Random`. A new mole spawns every 500 ms while fewer than 2 are up. Each mole rises (frames 0→1→2), holds frame 3 (the settled pose) while up, then hides (frames 2→1→0). The time a mole stays up shrinks as the round runs down, from 1200 ms at the start to 600 ms at the end (values in config).
4. **Scoring.** A click on an up mole is +1, and that mole drops back into its hole quickly (rise frames in reverse) with a floating "+1". A click that hits no mole (grass or an empty hole) is -1. A mole that escapes costs nothing. The score can go negative. A mole that has already been hit can't be hit again. Hits and misses are counted separately.
5. **HUD.** The score is shown top-right during the countdown and play.
6. **Hammer.** The OS cursor is hidden and the hammer sprite follows the mouse. Each click plays the 3-frame swing. The hit point is the hammer head, given as an offset in config.
7. **Screens.** Title ("Click to start") → countdown → play → game over. Game over shows the final score, hits, misses and the best score. A click or R on game over starts a new round with score, hits, misses, timer and moles all reset.
8. **High score.** The best score is saved to a JSON file in the user's data dir with an atomic write (write to a temp file, then rename). A missing or corrupt file counts as best = 0 and never crashes the game. The file is parsed with `JSON.parse` only.
9. **Sound.** The music loops as a `Gosu::Song` during the countdown and play, and stops at game over. The thud is a `Gosu::Sample` played on every scored click: normal pitch for a hit, lower pitch (speed ~0.7) for a miss. A missing or unloadable audio file is skipped silently.
10. **Timing.** All game logic runs on elapsed milliseconds passed in from the window, never on frame counts, so behavior is the same at any frame rate.

## Repo hygiene
- A `.gitignore` for a Ruby app: `.bundle/`, `vendor/bundle/`, `tmp/`, `coverage/`, `*.gem`, `.rubocop-*`, `*.log`, and OS/editor files (`.DS_Store`, `Thumbs.db`, `.vscode/`, `.idea/`). Commit `Gemfile.lock` (this is an app, not a gem). The high-score file lives outside the repo, in the user data dir.

## Out of scope for v1
Rails (phase 2: a leaderboard API that the game posts scores to), menus, settings, fullscreen, other difficulty modes.

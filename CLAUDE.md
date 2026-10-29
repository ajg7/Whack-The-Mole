# CLAUDE.md

This file guides Claude Code (claude.ai/code) when working in this repository.

## Project

Whack-The-Mole: a 2D whack-a-mole desktop game in Ruby using [Gosu](https://www.libgosu.org/), an open source 2D game library. Moles pop out of holes on a grid; the player clicks them before they hide; score and a round timer drive the game.

Two phases:
1. **Build** (now): Claude builds the game through the agent loop below. Sidekick mode is off.
2. **Teach** (later): Claude writes lessons and assessments that use this codebase to teach Ruby, Ruby principles, and gameplay programming best practices. The code is the future course material, so it must be idiomatic, small, and readable by a Ruby learner.

Spec: `docs/spec.md` (write it before the first planner run). Plans and review state live in `docs/review/`.

## Commands

Ruby is not installed on this machine yet. Install Ruby 3.3+ with DevKit (RubyInstaller for Windows), then:

- Install: `bundle install`
- Run: `bundle exec ruby bin/whack_the_mole`
- Test: `bundle exec rake test` (Minitest)
- Lint/format: `bundle exec rubocop` (autofix: `bundle exec rubocop -a`)
- Smoke launch (agents): `timeout 5 bundle exec ruby bin/whack_the_mole`; exit code 124 means it ran until killed, anything else is a crash.

## Architecture

- `bin/whack_the_mole`: thin entry point; requires the lib and calls `WhackTheMole::Window.new.show`.
- `lib/whack_the_mole/window.rb`: the only file that subclasses `Gosu::Window`. It translates Gosu callbacks (`update`, `draw`, `button_down`) into calls on the game and draws the game's state. No game rules here.
- `lib/whack_the_mole/*.rb`: game rules in plain Ruby (game state, moles, holes, scoring, timer). These files never `require "gosu"`, so they are testable without a window.
- Time is passed in (elapsed milliseconds from `Gosu.milliseconds` in the window), never read inside game logic. Randomness is injected (`Random.new(seed)`) so tests are deterministic.
- Assets in `assets/` (images, sounds, fonts), loaded only by the window. Constants (grid size, durations, colors) in one place: `lib/whack_the_mole/config.rb`.
- Tests in `test/`, mirroring `lib/`, Minitest only.
- Style: rubocop defaults plus `frozen_string_literal`; no code comments unless absolutely necessary, 2 lines at most.

## Workflow: build and review loop

Substantial work runs through six subagents defined in `.claude/agents/`: `planner` (Eevee), `coder` (Flareon), `reviewer` (Jolteon), `adversary` (Vaporeon), `gatekeeper` (Espeon), and `tester` (Umbreon). The main session orchestrates; it does not write the code itself.

Before round 1 of a phase or feature, run `planner` (Eevee) once. It reads `docs/spec.md` and the repo and writes `docs/review/plan.md` (or `plan-<feature>.md`). The planner is never part of the revision loop.

Each round N (max 3):
1. `coder` (Flareon) implements the plan (round 1) or fixes the items in `docs/review/round-(N-1)-verdict.md`, then commits.
2. `reviewer` (Jolteon) reviews the diff and writes `docs/review/round-N-review.md`.
3. `adversary` (Vaporeon) reviews that review and the code, and writes `docs/review/round-N-adversary.md`.
4. `gatekeeper` (Espeon) runs the checks and writes `docs/review/round-N-verdict.md`, whose first line is `VERDICT: SATISFIED` or `VERDICT: REVISE`.

After a `VERDICT: SATISFIED`, run `tester` (Umbreon) once. It writes tests from `docs/spec.md` (not from the implementation), edits only test code, and writes `docs/review/tester-report.md`. If it reports BLOCKING bugs, treat them as the required items of a new round (back to `coder`, then the usual reviewer/adversary/gatekeeper, then `tester` again) while rounds remain under the cap; otherwise escalate to the user. Tester work does not get its own extra rounds beyond the cap of 3.

Definition of satisfied: `bundle exec rake test` and `bundle exec rubocop` pass, the smoke launch runs without crashing, and the only remaining issues are minor and non-blocking.

If the verdict is REVISE, start the next round with only the verdict's required items passed to the coder. If round 3 still ends in REVISE (`ESCALATE: yes`), stop and give the user the open blocking items instead of looping. Pass state between agents through the files in `docs/review/`, not through chat, and don't share the coder's reasoning with the reviewers.

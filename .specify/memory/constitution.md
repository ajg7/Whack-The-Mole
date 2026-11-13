# Whack-The-Mole Constitution

## Core Principles

### I. Teachable Code

This repo is future course material for idiomatic Ruby, gameplay programming patterns, game
design, and object-oriented programming.

- Code MUST be small, flat, and readable by a Ruby learner; clarity beats cleverness.
- Names MUST describe purpose (`spawn_interval_ms`, not `t`); no single-letter names outside
  short blocks.
- Each class has one job; a method that needs a comment to explain what it does MUST be split
  or renamed instead.

Rationale: every line will be read by students, so a confusing line is a teaching bug.

### II. Game Logic Is Window-Free

- `lib/whack_the_mole/window.rb` is the only file that subclasses `Gosu::Window` or calls Gosu.
- Every other file under `lib/` MUST NOT `require "gosu"` and MUST NOT reference `Gosu::`.
- The window translates callbacks (`update`, `draw`, `button_down`) into calls on the game and
  draws its state; it contains no game rules.
- Enforcement: reviewer and gatekeeper grep `lib/` for `gosu` outside `window.rb`; any hit is
  blocking.

Rationale: rules testable without a window, and a clean seam to teach separation of concerns.

### III. Deterministic by Injection

- Time enters game logic only as elapsed milliseconds passed in by the window
  (`Gosu.milliseconds`); game logic MUST NOT read a clock.
- Randomness enters only as an injected `Random` instance; game logic MUST NOT call `rand`
  or `Random.new` without a seed passed in.
- Tests MUST use `Random.new(seed)` and explicit millisecond values.

Rationale: the same inputs always give the same game, so tests never flake.

### IV. Test Discipline

- Minitest only; files in `test/` mirror `lib/`.
- Every rule in `lib/` (spawning, hiding, hit detection, scoring, timer, round end) MUST have
  a test before the round can be SATISFIED.
- The tester writes tests from `specs/<feature>/spec.md`, not from the implementation, and edits only
  test code.
- `window.rb` is covered by the smoke launch, not unit tests.

### V. Simplicity

- YAGNI: build only what `specs/<feature>/spec.md` asks for.
- A new class is justified only when it owns state or a rule no existing class owns.
- A new gem MUST be named in the plan with a reason the standard library or Gosu cannot do
  the job, and the user approves it before the coder adds it.

## Style and Conventions

- `bundle exec rubocop` defaults plus `# frozen_string_literal: true` in every Ruby file.
- No code comments unless absolutely necessary, at most 2 lines.
- All constants (grid size, durations, colors, window size) live in
  `lib/whack_the_mole/config.rb`.
- `bin/whack_the_mole` is a thin entry point that requires the lib and calls
  `WhackTheMole::Window.new.show`.
- Assets live in `assets/` (images, sounds, fonts) and are loaded only by the window.

## Development Workflow

Every feature or bug fix lives in its own Spec Kit folder, `specs/NNN-<name>/` (written here as
`specs/<feature>/`), created by `/speckit-specify` along with a branch of the same name. It holds
`spec.md` (the input), `plan.md` (written by the planner), optional `tasks.md` (from
`/speckit-tasks`), and `review/` for every round, tester and assessment file. The orchestrator
passes the feature folder to each agent. State passes between agents only through files in
the feature folder, never through chat, and the coder's reasoning is not shared with reviewers.
The v1 build is recorded in `specs/001-whack-the-mole-v1/`.

1. **Plan**: `planner` (Eevee) runs once per phase or feature and writes the plan. It is never
   part of the revision loop.
2. **Rounds** (max 3), each round N:
   - `coder` (Flareon) implements the plan or the previous verdict's required items, then
     commits.
   - `reviewer` (Jolteon) writes `round-N-review.md`.
   - `adversary` (Vaporeon) writes `round-N-adversary.md`.
   - `gatekeeper` (Espeon) runs the quality gates and writes `round-N-verdict.md`, first line
     `VERDICT: SATISFIED` or `VERDICT: REVISE`.
3. **Test**: after SATISFIED, `tester` (Umbreon) writes spec-derived tests and
   `tester-report.md`. BLOCKING bugs become the required items of a new round while under the
   cap.
4. **Escalate**: if round 3 ends in REVISE, or tester BLOCKING bugs remain at the cap, stop and
   give the user the open blocking items.
5. **Assess**: once the loop finishes SATISFIED with no BLOCKING tester bugs, `assesser`
   (Slowbro) runs once, given the base commit before round 1, and writes the developer
   assessment (see below). The phase or feature is not complete until it exists.

### Developer Assessment

Purpose: the developer understands what the agents built and why, without having written it.

- Written to `specs/<feature>/review/assessment.md` after the Assess step.
- Format: multiple choice only. Each question has 4 options (A-D) with exactly one correct
  answer.
- Scope: MUST cover only what the agents developed in this phase or feature, i.e. the commits
  made during this loop, the plan, and the decisions recorded in `specs/<feature>/review/`. MUST NOT test
  general Ruby or Gosu knowledge, code that existed before the loop, or anything outside the
  diff.
- Coverage: every file added or materially changed gets at least one question. Questions
  cover both *what* (what a class or method does, where a rule lives) and *why* (why a design
  choice was made, citing the plan, a review finding, or a verdict item that drove it).
- Each question cites the file and line or the review file it is based on.
- An answer key follows the questions, separated under its own heading. Each answer gives the
  correct letter and a 1-3 sentence explanation of why it is right and why the most tempting
  wrong option is wrong.
- Size: 1-2 questions per changed file, 5 minimum, 20 maximum.

## Quality Gates

A round is SATISFIED only when all of these hold:

- `bundle exec rake test` passes.
- `bundle exec rubocop` passes with no offenses.
- Smoke launch `timeout 5 bundle exec ruby bin/whack_the_mole` exits 124 (ran until killed);
  any other exit code is a crash.
- No `gosu` reference in `lib/` outside `window.rb` (Principle II).
- Only minor, non-blocking issues remain.

Blocking: a failing gate, a spec requirement missing or wrong, a principle violation, a crash,
or an untested rule. Minor: naming nits, style preferences rubocop accepts, optional
refactors. Minor items are logged in the verdict but do not trigger a new round.

## Governance

- This constitution supersedes other practices. `CLAUDE.md` is the operational summary and
  MUST agree with it; on conflict, this file wins and `CLAUDE.md` is fixed. Agent definitions
  in `.claude/agents/` MUST also agree with it.
- Amendments are made through `/speckit-constitution`, recorded with a version bump and the
  Last Amended date, and committed with a `docs: amend constitution to vX.Y.Z` message.
- Versioning: MAJOR for removing or redefining a principle, MINOR for a new principle or
  section, PATCH for wording.
- Compliance: reviewer, adversary, and gatekeeper check every round against these principles;
  the gatekeeper's verdict names any violation as blocking.

**Version**: 1.1.0 | **Ratified**: 2026-11-13 | **Last Amended**: 2026-11-13

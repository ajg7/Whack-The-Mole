# Whack-The-Mole: a project-based Ruby curriculum

You'll learn Ruby, gameplay programming, and Ruby on Rails by reading, testing, and extending this game. Each phase has a **driving question**, a set of lessons that read real code from this repo, a **project** that changes the game, and a **summative assessment** you must pass before you start the next phase. A final cumulative assessment and capstone close the course.

| Phase | Driving question | Project | Gate |
|---|---|---|---|
| 1. Ruby basics | How does this game describe its world in Ruby? | Field Report script | [Phase 1 assessment](phase-1-ruby-basics/assessment.md) |
| 2. Objects and tests | How do you design game code that is safe to change? | Hit streaks, built test-first | [Phase 2 assessment](phase-2-objects-and-tests/assessment.md) |
| 3. Gameplay programming | What makes a game feel fair, responsive and alive? | The golden mole | [Phase 3 assessment](phase-3-gameplay/assessment.md) |
| 4. Ruby on Rails | How do players compare scores across machines? | Leaderboard API and website | [Phase 4 assessment](phase-4-rails/assessment.md) |
| Final | Can you design, build, test and explain a full feature end to end? | Online season (capstone) | [Final assessment](final/assessment.md) |

## How each phase works

1. **Read the driving question.** Keep it in mind; every lesson answers part of it.
2. **Work through the lessons in order.** Each lesson lists its objectives (like **[R1.4]**), the files to read, the concept, a *Try it* exercise in `irb`, and *Check yourself* questions. The check-yourself questions are formative: they don't count, but if you can't answer them you aren't ready for the gate.
3. **Build the project.** It's the "P" in PBL: the phase's ideas used together on a real change. Work on a branch (`git switch -c phase-1-field-report`). The project is graded with its rubric as part of the summative assessment.
4. **Take the summative assessment** when you're ready. Do it closed-book (no lessons, no searching), except where a part says otherwise. The repo is open-book: you may read the game's code.

## Passing a gate

Every phase assessment has three parts:

- **Part A, written** (closed-book): multiple choice, predict-the-output, and code-reading questions.
- **Part B, practical** (open-book): make a provided test file pass. Autograded with `ruby`.
- **Part C, project**: your phase project, graded with the rubric in the assessment.

You pass a phase when **all** of these hold:

- Part A: at least **80%** of points, *and* no objective with every one of its questions wrong.
- Part B: every provided test passes and `bundle exec rubocop` reports no offenses for your files.
- Part C: every rubric row scores **Meets** or better.

If you don't pass, look up the objective IDs of the questions you missed (each question lists the objectives it covers), redo those lessons, and retake only the parts you failed. Retake Part A with a fresh attempt a day later, not right after reading the answer key. Part B and C are fixed until green.

The final has its own rules; see [final/assessment.md](final/assessment.md).

## Grading

Answer keys are in [answer-keys/](answer-keys/). Don't open one until you've written all your answers for that part. The simplest way to grade is to paste your answers to Claude and ask: *"Grade my Phase N Part A answers against docs/curriculum/answer-keys/phase-N.md. Show my score per objective."* Ask for feedback on Part C the same way, pointing at the rubric.

## Setup

- Ruby 3.3+ with DevKit (RubyInstaller for Windows). Check with `ruby -v`.
- In the repo: `bundle install`, then `bundle exec rake test` should pass and `bundle exec ruby bin/whack_the_mole` should open the game.
- Phase 4 adds Rails: `gem install rails` (Rails 8.x).

## For curriculum maintainers

Objective IDs are defined only in lesson files (`**[R1.4]**` in an *Objectives* list) and referenced by assessment questions (`_Covers: R1.4_`). `ruby docs/curriculum/verify_coverage.rb` checks that every question covers only taught objectives, that every objective is assessed in its own phase, that the final assesses every phase, and that every question has an answer in its key. Run it after any edit.

Objective prefixes: **R** Ruby basics (phase 1), **O** objects and tests (phase 2), **G** gameplay (phase 3), **W** web and Rails (phase 4).

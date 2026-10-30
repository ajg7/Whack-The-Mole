# Final summative assessment

You can take the final after passing all four phase gates. It has three parts, and you complete the course when you pass all three.

| Part | What | Pass when |
|---|---|---|
| A | Cumulative written exam (closed-book) | 80% overall **and** at least 70% in each of sections R, O, G and W |
| B | Capstone project: online seasons | Every rubric row is **Meets** or better |
| C | Oral defense of your capstone | At least 5 of 6 questions answered fully |

The per-section minimum means you can't pass on strength in three areas while one is weak. If you fail a section, redo the lessons for the objectives you missed and retake that section only.

---

## Part A: cumulative written exam (closed-book, 52 points, pass at 42)

Write your answers in `practice/final/answers.md`. The questions combine ideas from several lessons and ask about situations you haven't seen. All `Config` values are as committed.

### Section R: Ruby (11 points, pass at 8)

#### F1 (2 pts)
Predict `RoundTimer.new(started_at: 0, duration_ms: 90_000).clock_label(500)` and show each step of the calculation.

_Covers: R1.4, R1.6_

#### F2 (2 pts)
Predict `Hole.grid.map(&:y).uniq` and explain why there are that many values.

_Covers: R1.12, R1.15_

#### F3 (1 pt)
What does `Hammer.new.frame(5000)` return, and which line decides it?

_Covers: R1.7, R1.8_

#### F4 (2 pts)
Given `def place(x, y, z = 1, scale:) = [x, y, z, scale]`, give the result or error for each call: `place(1, 2, scale: 4)`, `place(1, 2, 3, scale: 4)`, `place(1, 2, 3)`, `place(1, scale: 4)`. (Half a point each.)

_Covers: R1.9_

#### F5 (2 pts)
A teammate "simplifies" `Game#update_round` by replacing `moles.reject! { |mole| mole.gone?(now) }` with `moles = moles.reject { |mole| mole.gone?(now) }`. What happens when it runs, and why?

_Covers: R1.17, O2.2_

#### F6 (2 pts)
`LeaderboardClient#submit` returns `:ok`, `:rejected` or `:offline`, but `#top` returns hashes like `{"player_name" => "Ace"}`. Explain why one uses symbols and the other string keys.

_Covers: R1.3, R1.14_

### Section O: objects and tests (12 points, pass at 9)

#### F7 (2 pts)
Someone changes `Score` to `Score = Data.define(:hits, :misses)` with a `total` method. Name two things that break, and say why `Data` is the wrong choice here.

_Covers: O2.5, O2.1_

#### F8 (1 pt)
A teammate adds `attr_accessor :transport` to `LeaderboardClient` "so tests can swap it". Why is that worse than the current design?

_Covers: O2.2, O2.7_

#### F9 (2 pts)
Write the line in `Window#initialize` that builds the leaderboard client with its URL from `ENV['LEADERBOARD_URL']` (default `http://localhost:3000`). Why is it built in the window and passed around, rather than created inside the code that uses it?

_Covers: O2.7_

#### F10 (3 pts)
List three problems with this code for saving the current season's name.

```ruby
def save_season(name)
  File.write(@path, "{\"season\": \"#{name}\"}")
end

def load_season
  eval(File.read(@path))['season']
rescue
  'Season 1'
end
```

_Covers: O2.9, O2.10_

#### F11 (2 pts)
The `submit_async` test in phase 4 uses real time (`sleep` in a fake, and a clock check). Why is that acceptable there, when game-logic tests never use real time?

_Covers: O2.12, W4.11_

#### F12 (2 pts)
A player reports that golden moles sometimes give +1 instead of +3. Describe, step by step, how you'd fix it test-first.

_Covers: O2.13, O2.11_

### Section G: gameplay (13 points, pass at 10)

#### F13 (2 pts)
On slow Wi-Fi, the game freezes for a second at every game over. Diagnose the most likely cause and describe the fix.

_Covers: G3.1, W4.11_

#### F14 (3 pts)
The game is run on a machine that only manages 30 updates per second. For each, say whether it changes and how: (a) how long moles stay up, (b) when moles spawn, (c) how the hammer swing looks.

_Covers: G3.2_

#### F15 (3 pts)
You add a `:paused` state (press P during play). (a) Which `Game` methods need new `when` branches? (b) Because everything is timestamp-based, what goes wrong if pausing only changes `@state`? (c) Propose a fix.

_Covers: G3.3, G3.2_

#### F16 (2 pts)
A mole is up in the hole at `(512, 600)`. Does a click at `(540, 600)` hit it? Show `left`, `top`, the hit box edges and the hit point.

_Covers: G3.6_

#### F17 (2 pts)
(a) With a 1-in-8 golden chance, what's the probability that two spawns in a row are both golden? (b) Play-testers complain some rounds have no golden mole at all. Design a rule that guarantees at least one per round without making it predictable, and say how you'd test it.

_Covers: G3.7, G3.8_

#### F18 (1 pt)
Propose feedback for the moment the leaderboard confirms a score, following the three properties of good feedback.

_Covers: G3.9_

### Section W: web and Rails (11 points, pass at 8)

#### F19 (1 pt)
The game posts its score and gets `400 Bad Request`. What's the most likely bug in the client?

_Covers: W4.1, W4.7_

#### F20 (2 pts)
The 20-character name limit is enforced in the game's name entry *and* in the `Score` model. Why both?

_Covers: W4.5, W4.10_

#### F21 (2 pts)
Write the controller code that reads `params[:period]` (`today`, `week` or anything else meaning all-time) and picks the scores to show, using the `since` and `top` scopes. Unknown values must not cause an error.

_Covers: W4.6, W4.7_

#### F22 (2 pts)
Describe the fixtures and the integration test you'd write to prove `GET /scores.json?period=today` leaves out yesterday's scores.

_Covers: W4.9_

#### F23 (2 pts)
A player names themselves `Robert'); DROP TABLE scores;--`. What happens when the score is saved and when the leaderboard page is shown? Which two practices make it harmless?

_Covers: W4.10, W4.8_

#### F24 (2 pts)
To add "Today / This week / All time" links to the HTML leaderboard, which files change, and does `config/routes.rb` need a new route? Explain.

_Covers: W4.2, W4.3, W4.8_

### Section I: integration (5 points)

#### F25 (3 pts)
Map the game's architecture onto Rails': what in Rails corresponds to (a) the rule files like `game.rb`, (b) `Window#draw`, (c) `Window#button_down`? Give one reason both projects separate these concerns.

_Covers: G3.10, W4.2, O2.6_

#### F26 (2 pts)
The background thread puts the leaderboard result into a `Thread::Queue`. Where should the main thread take it out, and what's wrong with taking it out in `draw`?

_Covers: W4.11, G3.1, G3.4_

---

## Part B: capstone project, online seasons

**Driving question:** Can you design, build, test and explain a full feature end to end?

Build **online seasons**: players enter a name, scores go to a leaderboard that can show today, this week or all time, and the game shows where you placed.

### Requirements

**Game**
1. **Name entry.** The title screen asks for a name (1 to 20 characters) before "Click to start". The name is remembered between launches in a JSON file in the user data dir, with the same safety as `HighScore` (atomic write, corrupt file means no saved name). You'll need `Gosu::TextInput`, which the lessons don't cover: read its docs, and keep the cleaning rules (trim spaces, length) in a tested plain-Ruby class, not in the window.
2. **Submit and rank.** At game over, submit the score on a background thread. The server's `201` response includes the score's `rank` for today (1 = best). The game-over screen shows `You placed #N today`, or the status (`sending...`, `rejected`, `offline`).
3. **Today's top five** on the game-over screen, fetched on a background thread.
4. The game is fully playable with the server off.

**Leaderboard app**
5. `GET /scores.json` and `/scores` accept `period=today|week|all` (default `all`; unknown values mean `all`). The HTML page has links for the three periods and highlights the current one.
6. The `201` response from `POST /scores` adds `rank`: the position of that score among today's scores using the same ordering as `top`. Put the rank logic in the model and test it, including ties.
7. `rate_limit` on `create`, with a test that proves the 11th post in a minute gets `429`.

**Both**
8. Tests for every new rule, using the techniques from the course: seeded randomness, explicit times, temp dirs, fake transports, fixtures, integration tests.
9. All quality gates: game `rake test`, `rubocop`, smoke launch; app `bin/rails test`.
10. **Design doc** `docs/capstone.md` in the game repo, 1 to 2 pages: an architecture sketch (which objects and requests exist, and which thread does what), three design decisions with the alternatives you rejected and why, how you tested it, and what you'd do next.

### Rubric

| Criterion | Below | Meets | Exceeds |
|---|---|---|---|
| Functionality | A requirement is missing or broken | Requirements 1 to 7 work, shown in a short screen recording or live demo | Handles edge cases visibly (very long names pasted in, server restarted mid-round) |
| Ruby quality | Unidiomatic or duplicated code; RuboCop offenses | Small methods, clear names, idiomatic collections and blocks; RuboCop clean | A reader new to the code can follow it without comments |
| Object design | Rules in the window or controller; state exposed with writers | Rules in plain-Ruby classes and models; narrow public interfaces; dependencies injected | Each new class has one job you can state in a sentence |
| Gameplay engineering | Game freezes, time read in rules, or state machine bypassed | Loop never blocks; time and randomness passed in; name entry is a proper state in the state machine | Name entry and network status have clear, immediate feedback |
| Rails | Unsafe params, string SQL, untested statuses | Strong params, validations, scopes, escaped views, correct status codes, rate limiting | Rank computed in one query, not by loading all of today's scores |
| Tests | Key rules untested or flaky | Every rule in requirements 1 to 7 has a test; suite is deterministic | Tests read as a spec of the feature |
| Design doc | Missing or only describes what the code does | Covers all four parts in the requirement, with real trade-offs | Decisions cite specific course ideas (by objective ID) |

---

## Part C: oral defense

Ask Claude to run it: *"Run the final oral defense from docs/curriculum/final/assessment.md on my capstone. Read my code first. Ask the six questions one at a time, don't give hints, then grade each."*

The examiner asks six questions about **your** code, one from each list, and one follow-up on any answer that's vague:

1. **Ruby:** Pick a method you wrote and explain each line: what each value is and what's returned.
2. **Objects:** Why is this class a class (or `Data`)? What's in its public interface, and why nothing else?
3. **Tests:** Show the test you're proudest of. What bug would it catch? How do you know it's deterministic?
4. **Gameplay:** Walk through one game loop tick while a submission is in flight: what does each thread do?
5. **Rails:** Trace a `POST /scores` from the route to the JSON response, naming every file it passes through.
6. **Design:** Name a decision you'd make differently now, and why.

An answer is **full** when it's correct, uses the right terms, and points at the actual code. Pass with at least 5 of 6 full answers.

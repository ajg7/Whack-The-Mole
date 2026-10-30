# Phase 2: Objects and tests

**Driving question:** How do you design game code that is safe to change?

Phase 1 taught you to read Ruby. This phase is about *design*: why the game is split into `Score`, `Mole`, `RoundTimer`, `Hole` and the rest, why some are classes and some are `Data`, why `Game` asks for a `random:` and a `high_score:` instead of making its own, and how the tests in `test/` prove all of it works. Your answer to the driving question should end up something like "small objects with narrow interfaces, dependencies passed in, and tests that pin the behavior down".

---

## Lesson 2.1: Classes, objects and state

### Objectives
- **[O2.1]** Define a class with `initialize` and instance variables, create objects with `new`, and explain that each object has its own state.
- **[O2.2]** Expose state with `attr_reader` (and know `attr_writer`/`attr_accessor`), and explain why this game exposes readers only.

### Read
`lib/whack_the_mole/score.rb`, `lib/whack_the_mole/hammer.rb`, `lib/whack_the_mole/round_timer.rb`, `test/whack_the_mole/hole_score_test.rb`.

### Concept
A **class** is a blueprint; an **object** (instance) is one thing built from it. `Score.new` calls `initialize`, which sets the object's starting state in **instance variables**:

```ruby
class Score
  attr_reader :hits, :misses

  def initialize
    @hits = 0
    @misses = 0
  end

  def hit!
    @hits += 1
  end
end

a = Score.new
b = Score.new
a.hit!
a.hits  # => 1
b.hits  # => 0, b has its own @hits
```

Instance variables are private to the object. Outside code can't read `@hits` unless the class offers a method. `attr_reader :hits` writes that method for you (`def hits = @hits`). `attr_writer :hits` would write `def hits=(value)`, and `attr_accessor` writes both.

**Why readers only?** If `Score` had `attr_accessor :hits`, any code anywhere could do `score.hits = 999`. With readers only, the *only* ways to change a score are `hit!` and `miss!`, so the rules for changing it live in one place. That's **encapsulation**: the object guards its own state. When a bug changes the score wrongly, there are exactly two methods to look at.

Inside a class, `hits` (no `@`) calls the reader. `Score#total` uses `hits - misses`; using the reader instead of `@hits` means it would keep working if `hits` were ever computed instead of stored.

**The assignment trap.** Inside a method, `name = value` *always* creates a local variable, even when a reader called `name` exists. In `Game`, writing `moles = moles.reject { ... }` would make a new local `moles`, and because the local exists from that line on, the right-hand `moles` is that local too, still `nil`: `NoMethodError: undefined method 'reject' for nil`. To change the object's state, assign the instance variable (`@moles = ...`), mutate it (`moles.reject!`), or call a writer with an explicit receiver (`self.moles = ...`, which needs an `attr_writer`).

### Try it
1. In `irb` (after `require_relative 'lib/whack_the_mole'`): make two `WhackTheMole::Score` objects, call `hit!` on one, and compare.
2. Try `score.hits = 5`. What error do you get, and why?
3. Write a `Counter` class with `attr_reader :count`, `initialize(start = 0)` and `increment!`.

### Check yourself
1. What's the difference between `hits` and `@hits` inside `Score`?
2. What would you lose if `Score` used `attr_accessor`?
3. `Hammer.new` sets `@swung_at = nil`. Why set it explicitly instead of leaving it out?

---

## Lesson 2.2: Designing an interface

### Objectives
- **[O2.3]** Use `private` to hide helper methods, and explain how a small public interface makes code safer to change ("tell, don't ask").
- **[O2.4]** Write and call class methods (`def self.name`), and use `self.class` to reach them from an instance.

### Read
`lib/whack_the_mole/game.rb` (everything after `private`), `Hammer.hit_point`, `Hole.grid`, `HighScore.default_path` and `HighScore#initialize`.

### Concept
**Public vs private.** Every method below the `private` keyword can only be called from inside the object (without an explicit receiver). `Game` has a public interface of `update`, `click`, `start`, `clock_label`, `countdown_number` and the readers. `spawn_mole`, `whack_at`, `finish_round` and friends are private.

Why it matters: the window, the tests, and any future code can only depend on the public methods. You're free to rename, split or rewrite the private ones without breaking anyone. A small public interface is a promise you can keep.

**Tell, don't ask.** The window *tells* the game what happened (`@game.click(x, y, now:)`) instead of *asking* for its moles, checking each one itself, and changing the score. The rules stay inside `Game`, which is why `Window` has no game rules.

**Class methods** belong to the class itself, not to instances. Define them with `def self.name`:

```ruby
class Hammer
  def self.hit_point(x, y)    # called as Hammer.hit_point(10, 20)
    ...
  end
end
```

Use one when the behavior doesn't need any object's state. `Hammer.hit_point` only needs the click position and a constant. `Hole.grid` *builds* holes, so there are none yet to call it on. `HighScore.default_path` computes a path before any `HighScore` exists.

`self.class` inside an instance method refers to the object's class. `HighScore#initialize(path: self.class.default_path)` uses it so the default works even in a subclass.

### Try it
1. In `irb`: `WhackTheMole::Game.private_instance_methods(false)`. Compare with `public_instance_methods(false)`.
2. Make a `Game` and call `game.spawn_mole(0)`. Read the error.
3. Add `def self.zero = new` to your `Counter` from lesson 2.1 and call `Counter.zero`.

### Check yourself
1. Name three private methods of `Game`. Why should the tests not call them directly?
2. Why is `hit_point` a class method and `frame` an instance method in `Hammer`?
3. What does "tell, don't ask" look like in `Window#button_down`?

---

## Lesson 2.3: Value objects with `Data`

### Objectives
- **[O2.5]** Define value objects with `Data.define`, and explain value equality, immutability, `with`, and when to choose `Data` over a class.

### Read
`lib/whack_the_mole/hole.rb`, `lib/whack_the_mole/popup.rb`, `Game#spawn_mole` (`Hole.grid - moles.map(&:hole)`).

### Concept
Some objects are just a bundle of values that never change: a position, a color, a popup that started at a time. `Data.define` (Ruby 3.2+) makes such a class in one line:

```ruby
Hole = Data.define(:x, :y)

a = Hole.new(x: 128, y: 216)   # keywords
b = Hole.new(128, 216)         # or positional
a.x                            # => 128 (readers are generated)
a == b                         # => true: equal because the values are equal
a.equal?(b)                    # => false: still two different objects
a.with(y: 0)                   # => a new Hole(x: 128, y: 0); a is unchanged
Hole.new(x: 1)                 # ArgumentError: missing keyword: :y
```

There are no setters, and the object is frozen. You can add methods in the block, as `Hole.grid` and `Popup#alpha` do.

**Value equality matters here.** `Hole.grid - moles.map(&:hole)` builds a *fresh* grid of nine new `Hole` objects and subtracts the holes the moles are in. That only works because two `Hole`s with the same `x` and `y` count as equal. With a plain class, `==` would compare identity and nothing would ever be subtracted.

**Data or class?** Use `Data` when the thing *is* its values and never changes (`Hole`, `Popup`). Use a class when the thing has an identity and state that changes over time (`Score` counts up, `Mole` gets whacked, `Hammer` swings). A `Popup` doesn't move by changing its fields; its position is *computed* from `started_at` and `now`, so it can stay immutable.

`Struct` is the older cousin of `Data`: it also has value equality, but it's mutable by default. Prefer `Data` for values.

### Try it
1. Make two `WhackTheMole::Hole`s with the same coordinates. Compare `==`, `equal?` and `[a] - [b]`.
2. Make a `Popup` and try `popup.started_at = 5`. Then try `popup.with(started_at: 5)`.
3. Define `Point = Data.define(:x, :y) do def +(other) = with(x: x + other.x, y: y + other.y) end` and add two points.

### Check yourself
1. Why would `Hole.grid - moles.map(&:hole)` break if `Hole` were a plain class?
2. Why is `Mole` a class and not `Data`?
3. How does a `Popup` "rise" on screen if it's immutable?

---

## Lesson 2.4: Composition and inheritance

### Objectives
- **[O2.6]** Explain composition ("has-a"), inheritance ("is-a") with `<` and `super`, and why this game uses inheritance only for `Window`.

### Read
`Game#initialize` and `Game#start`, `lib/whack_the_mole/window.rb` (`class Window < Gosu::Window`, `initialize`, `button_down`, `needs_cursor?`).

### Concept
**Composition:** an object holds other objects and delegates work to them. `Game` *has a* `Score`, a `Hammer`, two `RoundTimer`s, a list of `Mole`s and a list of `Popup`s. Each part does one job; `Game` coordinates them. To change how time works, you change `RoundTimer`; `Game` doesn't care how.

**Inheritance:** `class Window < Gosu::Window` says a `Window` *is a* `Gosu::Window`. It gets all of Gosu's behavior (opening a window, running the loop) and **overrides** the hook methods Gosu calls: `update`, `draw`, `button_down`, `needs_cursor?`.

`super` calls the parent class's version of the current method:

- `super(Config::WIDTH, Config::HEIGHT)` in `initialize` passes the size to `Gosu::Window#initialize`.
- `else super` in `button_down` hands any key the game doesn't handle back to Gosu's default behavior.

**Prefer composition.** Inheritance welds a class to its parent: every parent change can break it, and Ruby allows only one parent. The game uses inheritance where the library demands it (Gosu wants a subclass of its window) and composition everywhere else. A good test: if you can't honestly say "X is a Y" in every situation, don't inherit.

### Try it
1. List everything a `Game` *has* after `start(0)`. Which classes do those objects come from?
2. `WhackTheMole::Window.ancestors.first(3)` (this one needs `require 'gosu'`, so run it with `bundle exec irb`).
3. Sketch (on paper) what would go wrong if `Game` inherited from `Score` to get `hit!` and `miss!`.

### Check yourself
1. What does `else super` in `button_down` do for a key like Escape?
2. Name two "has-a" relationships in `Game`.
3. Why is `Window` the only class that inherits from a library class?

---

## Lesson 2.5: Dependency injection and duck typing

### Objectives
- **[O2.7]** Explain dependency injection (passing collaborators in, usually as keyword arguments) and how it makes code testable.
- **[O2.8]** Explain duck typing: any object that responds to the right methods can stand in for another, including a fake in a test.

### Read
`Game#initialize`, `HighScore#initialize`, `Window#initialize` (where the real collaborators are built), `test/whack_the_mole/game_test.rb` (`setup`).

### Concept
`Game` needs randomness and a high-score store. It could make its own:

```ruby
def initialize
  @random = Random.new                 # different every run: untestable
  @high_score = HighScore.new          # writes to your real APPDATA folder in tests!
end
```

Instead it asks for them: `Game.new(random:, high_score:)`. This is **dependency injection**. The window passes real ones (`Random.new`, `HighScore.new`); the tests pass controlled ones (`Random.new(1)`, a `HighScore` pointing at a temp folder). Same game code, different collaborators. `HighScore.new(path:)` does the same for the file location.

The same idea explains why `now` is passed into every method instead of read with `Gosu.milliseconds` inside: time is a dependency too. A test can say "it's now 63,000 ms" without waiting a minute.

**Duck typing:** "if it walks like a duck and quacks like a duck, it's a duck". Ruby doesn't check classes; it just calls methods. `Game` only ever calls `high_score.best` and `high_score.record(total)`. So *any* object with those two methods works:

```ruby
FakeHighScore = Struct.new(:best) do
  def record(score) = self.best = [best, score].max
end

game = Game.new(random: Random.new(1), high_score: FakeHighScore.new(10))
```

No file is touched. The fake is useful when you want to test the game's use of the high score without touching disk. The real tests use a real `HighScore` in a temp dir, which tests more of the real thing; both are valid choices.

### Try it
1. Build a `Game` with the `FakeHighScore` above, play a round in `irb` by calling `click` and `update` with made-up times, and check `game.best`.
2. Make two `Game`s with `Random.new(5)`, run the same calls on both, and compare where their moles appear (`game.moles.map(&:hole)`).
3. Find the one place in the codebase where `Random.new` is called without a seed.

### Check yourself
1. Give two reasons `Game` takes `random:` instead of calling `Random.new` itself.
2. What two methods must an object have to be a `high_score:` for `Game`?
3. How is passing `now` into `update` a form of dependency injection?

---

## Lesson 2.6: Errors, files and JSON

### Objectives
- **[O2.9]** Raise and rescue exceptions: specific classes, method-level `rescue`, `rescue => e`, `ensure`, and why a bare `rescue` or rescuing `Exception` is a mistake.
- **[O2.10]** Read and write files and JSON safely: `File.read`/`File.write`, `JSON.parse`/`JSON.generate`, validating untrusted data, and the atomic write-then-rename pattern.

### Read
`lib/whack_the_mole/high_score.rb` (all of it), `Window#load_tiles`, `Window#load_audio`, `test/whack_the_mole/high_score_test.rb`, `test/whack_the_mole/high_score_edge_cases_test.rb`.

### Concept
**Exceptions.** When something goes wrong, Ruby **raises** an exception object, which unwinds the call stack until something **rescues** it. If nothing does, the program crashes with a message.

```ruby
def load
  data = JSON.parse(File.read(@path))
  ...
rescue JSON::ParserError, SystemCallError    # method-level rescue: covers the whole method body
  0
end

def save
  ...
rescue SystemCallError => e                  # => e gives you the exception object
  warn "Could not save high score: #{e.message}"
end
```

- Rescue **specific** classes: the errors you expect and know how to handle. `File.read` on a missing file raises `Errno::ENOENT`, a kind of `SystemCallError`; bad JSON raises `JSON::ParserError`.
- A bare `rescue` catches every `StandardError`, including your own typos (`NoMethodError`), turning bugs into silent wrong behavior. Rescuing `Exception` is worse: it also catches Ctrl-C and `exit`.
- `ensure` runs whether or not an error happened, for cleanup (closing something, removing a temp file).
- `raise ArgumentError, 'score must be an Integer'` raises your own. Raise when the caller made a mistake you can't sensibly recover from.

**Choose the response to fit the failure.** The game has three:
- High-score file missing or corrupt: rescue and use `0`. The game is still playable.
- Saving fails: `warn` to the console and carry on. The round is still over; losing a record isn't worth a crash.
- An image is missing: `abort` with a message (`Window#load_tiles`). The game can't be drawn without moles, so fail loudly and clearly.

**Files and JSON.** `File.read(path)` returns the contents as a String; `File.write(path, text)` replaces the file. `JSON.generate(best: 5)` turns Ruby into JSON text; `JSON.parse(text)` turns it back. **Never** use `eval` or `Marshal.load` on file contents: a file is untrusted input, and those can run code. `JSON.parse` only ever builds plain data.

Even plain data can be the wrong *shape*: `[]`, `{"best":"x"}`, `{"best":-4}` are all valid JSON. `load` validates the shape before trusting it (phase 1 lesson 1.6).

**Atomic write.** If the game crashed halfway through `File.write(@path, ...)`, the file could be left half-written and corrupt. `save` writes to `highscore.json.tmp` first, then `File.rename`s it over the real file. A rename is atomic on the same disk: readers see either the whole old file or the whole new one, never half. `FileUtils.mkdir_p` creates the folder (and any parents) if needed.

### Try it
1. In `irb`: `File.read('nope.json')` (read the class name), then wrap it in `begin ... rescue SystemCallError => e ... end` and print `e.class`.
2. `JSON.parse('not json')`, then `JSON.parse('[]')`. Which raises? Why does `load` still return `0` for the second?
3. Write `def parse_age(text) = Integer(text)` and call it with `'12'` and `'twelve'`. What does `Integer()` raise?

### Check yourself
1. Why does `HighScore#load` rescue `SystemCallError` and not just `Errno::ENOENT`?
2. Why is losing a save handled with `warn`, but a missing image with `abort`?
3. What could go wrong without the temp-file-then-rename step?

---

## Lesson 2.7: Testing with Minitest

### Objectives
- **[O2.11]** Write Minitest tests: a test class, `setup`/`teardown`, `test_` methods, `assert_equal`, `assert`/`refute`, `assert_nil`, `assert_predicate`, `assert_raises`; structure each test as arrange, act, assert; run one file or all tests.
- **[O2.12]** Make tests deterministic: seeded `Random`, explicit time values, and temporary directories for file tests.

### Read
`test/test_helper.rb`, `test/whack_the_mole/round_timer_test.rb`, `test/whack_the_mole/mole_test.rb`, `test/whack_the_mole/game_test.rb`, `test/whack_the_mole/high_score_test.rb`.

### Concept
```ruby
require_relative '../test_helper'

module WhackTheMole
  class RoundTimerTest < Minitest::Test
    def setup                       # runs before every test_ method
      @timer = RoundTimer.new(started_at: 1000, duration_ms: 60_000)
    end

    def test_expires_at_the_end      # every method starting with test_ is a test
      refute @timer.expired?(60_999)               # act + assert
      assert @timer.expired?(61_000)
    end
  end
end
```

The assertions you'll use most:

| Assertion | Passes when |
|---|---|
| `assert_equal expected, actual` | `expected == actual` (expected first!) |
| `assert x` / `refute x` | `x` is truthy / falsy |
| `assert_nil x` | `x` is `nil` |
| `assert_predicate obj, :whacked?` | `obj.whacked?` is truthy (nicer failure message than `assert obj.whacked?`) |
| `assert_raises(ArgumentError) { ... }` | the block raises that error |
| `assert_empty x`, `assert_includes list, item` | what they say |

**Arrange, act, assert.** Set things up, do one thing, check the result. Leave a blank line before the assertions (RuboCop's Minitest rules expect it), which makes the three steps visible.

**Running tests.** `bundle exec rake test` runs everything. `bundle exec ruby -Itest test/whack_the_mole/mole_test.rb` runs one file. Add `-n test_phases` to run one test by name.

**Determinism.** A test that sometimes fails is worse than no test, because people learn to ignore it. This repo removes every source of randomness from tests:

- **Random:** `Random.new(1)` always produces the same sequence, so mole spawns are the same every run.
- **Time:** tests pass numbers like `@game.update(63_000)` instead of waiting. The whole 60-second round runs in microseconds.
- **Files:** `Dir.mktmpdir` makes a fresh empty folder in `setup`; `teardown` deletes it with `FileUtils.remove_entry`. Tests never touch your real high-score file and never see each other's files.

**Test behavior, not internals.** `game_test.rb` drives the game only through its public interface (`click`, `update`, readers). That's why private methods can be rewritten freely: the tests don't know they exist.

### Try it
1. Run only `mole_test.rb`. Then run only `test_phases` inside it.
2. Break something on purpose: change `MAX_MOLES` to 3 and run the tests. Read the failure message. Change it back.
3. Add a test to your own scratch file for your `Counter` class from lesson 2.1.

### Check yourself
1. Why must `assert_equal` take the expected value first?
2. What three things in `game_test.rb` would make tests flaky if they weren't controlled?
3. Why does `high_score_test.rb` need a `teardown` but `mole_test.rb` doesn't?

---

## Lesson 2.8: TDD and RuboCop

### Objectives
- **[O2.13]** Work test-first with red, green, refactor, and explain what each step protects against.
- **[O2.14]** Use RuboCop to keep a consistent style: run it, autofix, read an offense, and explain the project's `.rubocop.yml` choices.

### Read
`.rubocop.yml`, `docs/review/tester-report.md` (how the tester wrote tests from the spec, not the code), the git log (`git log --oneline`).

### Concept
**Test-driven development (TDD)** is a loop:

1. **Red:** write one small test for behavior that doesn't exist yet. Run it and *watch it fail*. A test you've never seen fail might not be testing anything.
2. **Green:** write the simplest code that passes it. Don't add anything the test doesn't need.
3. **Refactor:** clean up names and duplication while the tests stay green. The tests are your safety net.

Then repeat with the next behavior. The tests end up describing exactly what the code does, and each piece of code exists because a test needed it.

**Writing tests from the spec, not the code** catches a different class of bug: misunderstandings. The `tester` agent in this repo wrote tests from `docs/spec.md` without looking at the implementation, so its tests checked what the game *should* do.

**RuboCop** checks style and some likely bugs. Run `bundle exec rubocop`; fix automatically with `bundle exec rubocop -a` (safe fixes only). Each offense names a cop, like `Style/StringLiterals` or `Metrics/MethodLength`. Look it up when you don't understand it; the docs give the reason.

`.rubocop.yml` tunes the defaults for this project:
- `NewCops: enable` turns on cops added in newer RuboCop versions.
- `Style/Documentation: Enabled: false`: no class comments required (the project avoids comments).
- `Naming/MethodParameterName: AllowedNames: [id, x, y]`: short names are fine where they're the natural names.
- `Metrics/*` excludes `window.rb`: drawing code is long and flat by nature; the rules files are kept small.

A consistent style means a diff only shows real changes, and readers spend their attention on logic, not formatting.

### Try it
1. TDD a `Counter#reset!` method: test first, see it fail, implement, see it pass.
2. Add `x = "double"` somewhere in a scratch file and run `bundle exec rubocop` on it. Fix it with `-a`.
3. Read `git log --oneline` and find a commit that fixed a bug. Was a test added with it?

### Check yourself
1. Why must you see the test fail before writing the code?
2. What's allowed in the refactor step, and what isn't?
3. Why does `.rubocop.yml` exclude `window.rb` from the metrics cops but not `game.rb`?

---

## Phase 2 project: hit streaks, test-first

Add **hit streaks** to the game. A streak is the number of hits in a row.

**Rules (your spec):**
1. Each hit adds one to the current streak.
2. A miss resets the current streak to 0.
3. A mole that escapes (goes back down without being whacked) also resets the current streak.
4. The game remembers the best streak of the round. A new round starts both at 0.
5. The game-over screen shows `Best streak: N` on its own line.
6. Scoring (`total`) doesn't change.

**How:**
1. Branch: `git switch -c phase-2-streaks`.
2. Decide where streaks live: a new `Streak` class, or inside `Score`? Write your reasoning (3 to 5 sentences) in `practice/phase2/design.md`, referring to at least one idea from this phase (encapsulation, composition, value object vs class, interface size).
3. TDD it. Commit each red test before making it pass (`git commit -m "Red: miss resets streak"`), so the history shows the loop.
4. Rule 3 needs `Game` to notice escaped moles in `update_round`. Test it through `Game`'s public interface, with a seeded `Random` and explicit times.
5. Draw the line in `Window#draw_game_over`. The window must only *read* the streak; no rules there.
6. `bundle exec rake test` and `bundle exec rubocop` pass; the smoke launch (`timeout 5 bundle exec ruby bin/whack_the_mole`, exit code 124) doesn't crash.

The rubric is in the [phase 2 assessment](assessment.md), Part C.

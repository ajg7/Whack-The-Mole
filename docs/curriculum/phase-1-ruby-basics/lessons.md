# Phase 1: Ruby basics

**Driving question:** How does this game describe its world in Ruby?

By the end of this phase you can read every line of `config.rb`, `hole.rb`, `score.rb`, `round_timer.rb` and `hammer.rb`, explain what each does, and write small Ruby scripts of your own. Classes are only touched lightly here; phase 2 is about them.

Keep `irb` open the whole time. Every *Try it* is meant to be typed, not read.

---

## Lesson 1.1: Running Ruby and the project

### Objectives
- **[R1.1]** Run Ruby code three ways: `irb`, `ruby file.rb`, and `bundle exec` inside this project.
- **[R1.2]** Explain what a gem, the `Gemfile`, `Gemfile.lock`, Bundler and Rake are for.

### Read
`Gemfile`, `Gemfile.lock` (skim), `Rakefile`, `bin/whack_the_mole`, `run.ps1`.

### Concept
Ruby is an interpreted language: `ruby some_file.rb` reads the file and runs it top to bottom. `irb` (interactive Ruby) runs one line at a time and prints each result, which makes it the best place to experiment.

A **gem** is a packaged Ruby library. This game uses `gosu` (graphics, sound, input), `minitest` (tests), `rake` (task runner) and `rubocop` (style checker). The **Gemfile** lists the gems the project needs and the version ranges it accepts: `gem 'gosu', '~> 1.4'` means "1.4 or newer, but below 2.0". **Bundler** reads the Gemfile, picks exact versions that fit together, installs them (`bundle install`) and writes those exact versions to **Gemfile.lock**. The lock file is committed so everyone runs the same versions.

`bundle exec <command>` runs a command using exactly the gems in the lock file. That's why every command in this repo starts with it:

```sh
bundle exec ruby bin/whack_the_mole   # play
bundle exec rake test                 # run all tests (Rake runs the :test task in Rakefile)
bundle exec rubocop                   # check style
```

**Rake** is Ruby's task runner. The `Rakefile` defines a `test` task that loads every `test/**/*_test.rb` file, and makes it the default task, so plain `bundle exec rake` runs the tests too.

The `group :development, :test do ... end` block in the Gemfile marks gems that are needed to develop the game but not to play it.

### Try it
1. Run `irb`, type `1 + 2`, then `"mole".upcase`, then `exit`.
2. Make a file `hello.rb` containing `puts "Hello, #{ENV.fetch('USERNAME', 'player')}"` and run it with `ruby hello.rb`.
3. Run `bundle exec rake test` and read the summary line. How many tests ran?

### Check yourself
1. What is the difference between `Gemfile` and `Gemfile.lock`? Which one do you edit by hand?
2. Why run `bundle exec rake test` instead of `rake test`?
3. What does `'~> 1.4'` allow?

---

## Lesson 1.2: Values, types and numbers

### Objectives
- **[R1.3]** Identify Ruby's core value types (Integer, Float, String, Symbol, `nil`, `true`/`false`) and explain when to use a Symbol instead of a String.
- **[R1.4]** Predict the result of integer and float arithmetic, including integer division, `%`, `to_f`, `round`, `ceil`, `clamp` and `divmod`.

### Read
`lib/whack_the_mole/config.rb`, `lib/whack_the_mole/round_timer.rb`, `lib/whack_the_mole/hammer.rb` (the `frame` method).

### Concept
In Ruby **everything is an object**, even numbers: `5.even?`, `nil.to_s`, `3.times`. You can always ask a value what it is with `.class`.

| Type | Examples from this repo | Notes |
|---|---|---|
| Integer | `640`, `60_000`, `0xff_4caf50` | `_` is a visual separator only. `0x` is hexadecimal, used for colors (alpha, red, green, blue). |
| Float | `0.7`, `1000.0`, `0.5` | Has a decimal point. |
| String | `'Whack-The-Mole'`, `"Score: #{...}"` | Text. |
| Symbol | `:title`, `:playing`, `:hit` | A name. The same symbol is always the same object. |
| `nil` | `@swung_at = nil` | "No value". |
| `true` / `false` | `whacked?` returns one | Booleans. |

**Symbol vs String.** Use a Symbol when the value is an *identifier* from a fixed set chosen by the programmer: game states (`:title`, `:countdown`), mole phases (`:rising`, `:up`), results (`:hit`, `:miss`). Use a String for text that is shown to a person or comes from outside (a file, the user). `:up.to_s` gives `"up"`; `"up".to_sym` gives `:up`.

**Integer division truncates.** When both sides are Integers, `/` gives an Integer, rounding toward negative infinity:

```ruby
7 / 2        # => 3
-7 / 2       # => -4
7 % 2        # => 1 (remainder)
7.0 / 2      # => 3.5 (one Float makes the result a Float)
7.to_f / 2   # => 3.5
```

The game relies on this. In `Hammer#frame`, `(now - @swung_at) / Config::SWING_FRAME_MS` is "how many 50 ms steps have passed": 0 to 49 ms gives 0, 50 to 99 ms gives 1, and so on. That integer is the animation frame.

When you *want* a fraction, convert first. `RoundTimer#elapsed_fraction` uses `remaining_ms(now).to_f / @duration_ms`, because `30_000 / 60_000` would be `0`.

**Rounding and limits:**

```ruby
2.4.round          # => 2
2.5.round          # => 3 (halves round away from zero)
2.1.ceil           # => 3 (always up)
2.9.floor          # => 2 (always down)
15.clamp(0, 10)    # => 10
-3.clamp(0, 10)    # => 0
125.divmod(60)     # => [2, 5] (quotient and remainder)
```

`RoundTimer#seconds_left` uses `ceil` so the clock shows `1` for the whole last second instead of `0`. `remaining_ms` uses `clamp` so time left never goes below zero or above the round length. `clock_label` uses `divmod(60)` to split seconds into minutes and seconds.

### Try it
1. In `irb`: `0xff_4caf50.class`, `:playing.class`, `nil.class`.
2. Predict, then check: `59_999 / 1000`, `(59_999 / 1000.0).ceil`, `(1 / 1000.0).ceil`, `(0 / 1000.0).ceil`.
3. Predict `Hammer`'s frame for 0, 49, 50, 149 and 150 ms after a swing, using the rule `step < 3 ? step : 0`.

### Check yourself
1. Why is the game state a Symbol and not a String like `"playing"`?
2. What does `30_000 / 60_000` return? How would you get `0.5`?
3. What does `(remaining / 1000.0).ceil` show when 1 ms remains? When 0 ms remains?

---

## Lesson 1.3: Variables, constants and strings

### Objectives
- **[R1.5]** Distinguish local variables, instance variables (`@name`) and constants, and explain `freeze` and the `# frozen_string_literal: true` comment.
- **[R1.6]** Build strings with interpolation and `format`, and choose single or double quotes correctly.

### Read
`lib/whack_the_mole/config.rb`, the first line of every `.rb` file, `RoundTimer#clock_label`, `Window#draw_status` and `Window#draw_game_over`.

### Concept
- A **local variable** starts lowercase (`now`, `free_holes`, `up_ms`) and exists only inside the method or block where it's assigned.
- An **instance variable** starts with `@` (`@score`, `@swung_at`) and belongs to one object, living as long as the object does. Phase 2 covers these properly; for now, know that `@swung_at` in `Hammer` is remembered between calls.
- A **constant** starts with a capital letter (`WIDTH`, `ROUND_MS`, `FRAMES`). It's meant to be set once. Ruby warns if you reassign one. Constants can be computed from other constants: `GRID_LEFT = (WIDTH - (GRID_COLS * CELL_SIZE)) / 2`.

**Freezing.** A constant only stops you from pointing the name at a new object; the object itself could still be changed. `HAMMER_HEAD_OFFSET = [-24, -28].freeze` freezes the array, so `HAMMER_HEAD_OFFSET << 5` raises `FrozenError`. The magic comment `# frozen_string_literal: true` on line 1 freezes every string literal in that file, which prevents accidental mutation and lets Ruby reuse the same string object. RuboCop requires it in this project.

```ruby
# frozen_string_literal: true
name = 'mole'
name << 's'          # FrozenError: can't modify frozen String
name += 's'          # fine: makes a new string and points name at it
```

**Strings.** Single quotes are literal: `'Score: #{x}'` prints the braces. Double quotes allow **interpolation** and escapes like `\n`: `"Score: #{@game.score.total}"` puts the value into the text. RuboCop's default style is single quotes unless you need interpolation or escapes, which is why the repo mixes both.

**`format`** builds a string from a template. `RoundTimer#clock_label` uses named references:

```ruby
format('%<minutes>d:%<seconds>02d', minutes: 1, seconds: 5)  # => "1:05"
```

`%<seconds>02d` means "the `seconds` value as an integer, at least 2 digits, padded with zeros". `minutes:, seconds:` in the call is shorthand for `minutes: minutes, seconds: seconds` (Ruby 3.1+).

### Try it
1. In `irb` (where strings are not frozen) compare `s = 'a'; s << 'b'; s` with the same code after running `s = 'a'.freeze`.
2. Predict, then check: `format('%<m>d:%<s>02d', m: 0, s: 9)` and `"#{3 + 4} moles"`.
3. Why can `GRID_LEFT` be a constant even though it's calculated?

### Check yourself
1. What is wrong with `'Hits: #{hits}'`?
2. `HAMMER_HEAD_OFFSET` is a constant. Why does it also need `.freeze`?
3. Name one local variable, one instance variable and one constant in `game.rb`.

---

## Lesson 1.4: Conditionals and truthiness

### Objectives
- **[R1.7]** Write and read `if`/`elsif`/`else`, `unless`, modifier forms, the ternary operator and `case`/`when`.
- **[R1.8]** Apply Ruby's truthiness rule (only `nil` and `false` are falsy), guard clauses, `&&`/`||`/`!`, and safe navigation `&.`.

### Read
`Game#update`, `Game#click`, `Mole#phase`, `Hammer#frame`, `Window#sync_music`, `Window#play_thud`.

### Concept
**Forms of `if`:**

```ruby
if age < TRANSITION_MS then :rising        # then is optional; it allows one-line branches
elsif age < TRANSITION_MS + @up_ms then :up
else :gone
end

start(now) if now - @finished_at >= 1000  # modifier if: one statement, condition after
return 0 unless @swung_at                  # unless = "if not"
step < FRAMES ? step : 0                   # ternary: condition ? value_if_true : value_if_false
```

In Ruby, `if` and `case` are **expressions**: they return the value of the branch that ran. `Mole#phase` doesn't say `return :rising`; the `if` chain's value becomes the method's return value.

**`case`/`when`** compares one value against several options with `===`. For symbols that means equality:

```ruby
case state
when :countdown then start_round(now) if @countdown.expired?(now)
when :playing then update_round(now)
end
```

If no `when` matches and there's no `else`, `case` returns `nil` and does nothing. `Game#update` relies on this: in `:title` and `:game_over`, update does nothing.

**Truthiness.** Only `nil` and `false` are falsy. Everything else is truthy, including `0`, `""` and `[]`. So `return 0 unless @swung_at` means "if the hammer has never swung (`@swung_at` is `nil`), return frame 0".

**Guard clauses** exit early so the rest of the method can assume the good case: `return miss unless mole` and `return unless mole.hittable?(now)` in `Game#whack_at`.

**Boolean operators.** `&&` (and), `||` (or), `!` (not). They short-circuit: in `a && b`, `b` is never evaluated if `a` is falsy. `!@whacked_at.nil?` reads "not nil", i.e. "has been whacked".

**Safe navigation `&.`** calls a method only if the receiver is not `nil`. `@song&.play(true)` plays the song if it loaded, and quietly does nothing if loading failed and `@song` is `nil`.

### Try it
1. Predict: `0 ? 'yes' : 'no'`, `nil ? 'yes' : 'no'`, `[] ? 'yes' : 'no'`.
2. Predict: `x = case 5 when 1..3 then :low when 4..6 then :mid end`. (Ranges match with `===` by inclusion.)
3. Predict `nil&.upcase` and `'a'&.upcase`.

### Check yourself
1. In `Game#click`, what happens on a click during `:countdown`? Point to the line that decides it.
2. Rewrite `step < FRAMES ? step : 0` as a full `if`/`else`.
3. Why does `Window#sync_music` start with `return if @game.state == @previous_state`?

---

## Lesson 1.5: Methods

### Objectives
- **[R1.9]** Define and call methods with positional, default, keyword and required keyword parameters, relying on implicit return.
- **[R1.10]** Follow naming conventions: `?` for predicates, `!` for "dangerous" or mutating versions, `snake_case` for names.
- **[R1.11]** Use multiple return values, multiple assignment (destructuring) and the splat operator `*`.

### Read
`Hammer.hit_point`, `Game#click`, `Game#whack_at`, `Window#draw_center`, `Mole#hittable?`, `Score#hit!`.

### Concept
```ruby
def draw_center(text, y = Config::HEIGHT / 2)  # positional + default value
def initialize(random:, high_score:)           # required keywords: caller must name them
def initialize(path: self.class.default_path)  # keyword with a default
def click(x, y, now:)                          # positional and keyword mixed
```

Calls: `draw_center('Game over')`, `Game.new(random: Random.new(1), high_score: hs)`, `@game.click(10, 20, now: 500)`. Keyword arguments make calls readable (`now: 500` says what 500 is) and order-independent. Leaving out a required keyword raises `ArgumentError`.

**Implicit return.** A method returns the value of its last expression. `Score#total` is just `hits - misses`. `return` is only needed to leave early.

**Naming conventions.**
- Methods ending in `?` return true or false: `expired?`, `hittable?`, `whacked?`, `contains?`.
- Methods ending in `!` are the "careful, this changes something" version. Often there's a pair: `reject` returns a new array, `reject!` changes the array in place. `Score#hit!` and `miss!` use `!` to signal that they mutate the score.
- Methods and variables are `snake_case`; classes and modules are `CamelCase`; constants are `SCREAMING_SNAKE_CASE`.

**Multiple return and destructuring.** A method can return an array, and the caller can unpack it:

```ruby
def self.hit_point(x, y)
  dx, dy = Config::HAMMER_HEAD_OFFSET   # dx = -24, dy = -28
  [x + dx, y + dy]
end

hx, hy = Hammer.hit_point(100, 100)     # hx = 76, hy = 72
minutes, seconds = 125.divmod(60)       # 2, 5
```

**Splat `*`** spreads an array into separate arguments. `whack_at(*Hammer.hit_point(x, y), now)` turns `[76, 72]` into `whack_at(76, 72, now)`.

### Try it
1. Write `def lerp(from, to, fraction) = from + ((to - from) * fraction)` in `irb` and call `lerp(1200, 600, 0.5)`. (The `def name(args) = expr` form is a one-line "endless" method.)
2. Define `def greet(name, greeting: 'Hi') = "#{greeting}, #{name}"`. Call it with and without `greeting:`.
3. `a, b = [1, 2, 3]`: what are `a` and `b`? What about `a, *b = [1, 2, 3]`?

### Check yourself
1. Why is `now:` a keyword argument in `Game#click` but `x` and `y` are positional?
2. What does `whack_at(*[3, 4], 10)` pass as each argument?
3. Name a method in this repo that ends in `?` and one that ends in `!`. What do the suffixes promise?

---

## Lesson 1.6: Arrays, ranges and hashes

### Objectives
- **[R1.12]** Create and use arrays: literals, `%i[]`/`%w[]`, `<<`, indexing, `size`, `include?`, `-`, `product`, `sample`.
- **[R1.13]** Use inclusive (`..`) and exclusive (`...`) ranges and `between?`.
- **[R1.14]** Create and read hashes, and explain why JSON data comes back with string keys.

### Read
`Hole.grid`, `Game#spawn_mole`, `Mole#hittable?`, `Mole#contains?`, `HighScore#load` and `#save`, `Window#draw_moles` (indexing into `@moles`).

### Concept
**Arrays** are ordered lists.

```ruby
moles = []
moles << mole                 # append
moles.size                    # count
@moles[3]                     # index (0-based); @moles is the list of sprite frames
%i[rising up]                 # => [:rising, :up] (array of symbols)
%w[a b]                       # => ["a", "b"] (array of strings)
%i[rising up].include?(:up)   # => true
[1, 2, 3, 4] - [2, 4]         # => [1, 3] (remove every element found in the right side)
[0, 1].product([0, 1])        # => [[0, 0], [0, 1], [1, 0], [1, 1]] (every pair)
[5, 6, 7].sample(random: Random.new(1))  # one random element, repeatable with a seed
```

`Game#spawn_mole` combines these: `Hole.grid - moles.map(&:hole)` is "every hole minus the occupied ones", and `.sample(random: @random)` picks one of the free holes.

**Ranges** describe a span. `0..3` includes 3 (`0, 1, 2, 3`); `0...3` excludes it (`0, 1, 2`). `Hole.grid` uses `(0...rows)` because a 3-row grid has rows 0, 1 and 2. `x.between?(a, b)` is true when `a <= x <= b`; `Mole#contains?` uses it to check that a point is inside the hit box on both axes.

**Hashes** map keys to values.

```ruby
data = { best: 5 }    # symbol key: shorthand for { :best => 5 }
data[:best]           # => 5
data['best']          # => nil (a different key!)
data.fetch(:best)     # => 5; fetch raises KeyError if the key is missing
data.key?(:best)      # => true

counts = Hash.new(0)  # missing keys read as 0 instead of nil, handy for counting
counts[:a] += 1       # => { a: 1 }
%i[a b a].tally       # => { a: 2, b: 1 } (the built-in way to count)
```

JSON has no symbols, only strings. `JSON.generate(best: 5)` writes `{"best":5}` and `JSON.parse` reads it back as `{"best" => 5}`, with a **string** key. That's why `HighScore#load` reads `data['best']` while `save` writes `best: best`.

Data read from a file could be anything (someone may have edited it), so `HighScore#load` checks its shape before trusting it: `data.is_a?(Hash)` (is it a Hash at all?), `data['best'].is_a?(Integer)` (is the value a whole number, not `"5"` or `2.5`?) and `.positive?` (is it above zero?). `is_a?` asks whether an object belongs to a class; it works on any value, even `nil`.

### Try it
1. Build a 2×2 grid: `(0...2).to_a.product((0...2).to_a)`. What would `(0..2)` give instead?
2. `[1, 2, 3, 4, 5, 6, 7, 8, 9] - [5, 9]` and `.sample(random: Random.new(42))`. Run the sample twice with a new `Random.new(42)` each time. Same answer?
3. `require 'json'; JSON.parse('{"best": 3}')[:best]`. Why `nil`?

### Check yourself
1. How many holes does `Hole.grid(cols: 4, rows: 2)` return? In what order?
2. Is `10.between?(10, 20)` true? Is `20`?
3. Why must `Game#spawn_mole` subtract occupied holes before sampling?

---

## Lesson 1.7: Blocks and iteration

### Objectives
- **[R1.15]** Iterate and transform collections with blocks: `each`, `map`, `select`/`reject`, `find`, `each_with_index`, `each_cons`, `times`, and the `&:method` shorthand.
- **[R1.16]** Write a method that takes a block with `yield`, and explain what happens to an exception raised inside the block.
- **[R1.17]** Explain the difference between non-mutating methods (`reject`, `map`) and mutating ones (`reject!`, `<<`), and when each is appropriate.

### Read
`Game#update_round`, `Game#whack_at`, `Game#spawn_mole`, `Hole.grid`, `Window#draw_hole`, `Window#draw_game_over`, `Window#load_audio`.

### Concept
A **block** is a chunk of code passed to a method, written with `{ ... }` (one line) or `do ... end` (several lines). The method decides when to run it and with what arguments (between `| |`).

```ruby
Hole.grid.each { |hole| draw_hole(hole) }                 # do something per item
moles.map(&:hole)                                         # transform: [mole, mole] -> [hole, hole]
moles.find { |candidate| candidate.contains?(x, y) }      # first match, or nil
moles.reject! { |mole| mole.gone?(now) }                  # remove matches, in place
lines.each_with_index { |line, i| draw_center(line, y0 + (i * 48)) }
points.each_cons(2) { |(x1, y1), (x2, y2)| ... }          # overlapping pairs: [p0,p1], [p1,p2], ...
3.times { |i| puts i }                                    # 0, 1, 2
```

`&:hole` is shorthand for `{ |m| m.hole }`. `|(x1, y1), (x2, y2)|` destructures each of the two points into its coordinates. `select` keeps the items where the block is truthy; `reject` drops them.

**Mutating or not.** `reject` returns a *new* array and leaves the original alone; `reject!` changes the original. `Game#update_round` uses `moles.reject!` because the game's own list of live moles must shrink. Prefer the non-mutating form when you're computing something new (like `free_holes`), and the mutating form only when you mean to change state you own.

**Writing a method that takes a block.** Inside a method, `yield` runs the block the caller passed and returns its value:

```ruby
def load_audio
  yield
rescue RuntimeError
  nil
end

@song = load_audio { Gosu::Song.new(asset('music.mp3')) }
```

`load_audio` runs the block. If the block raises a `RuntimeError` (Gosu raises one when a file can't be loaded), the error travels up out of the block into `load_audio`, where `rescue` catches it and the method returns `nil`. `raise 'some message'` raises a `RuntimeError`, which is handy for trying this out. Other kinds of error (like `ZeroDivisionError` from `1 / 0`) are not caught by `rescue RuntimeError` and keep travelling up. One method gives the same "try it, fall back to `nil`" behavior to both the song and the thud. Phase 2 covers `rescue` in depth.

### Try it
1. `[3, 8, 1, 9].select(&:even?)`, `.map { |n| n * 10 }`, `.find { |n| n > 5 }`.
2. `a = [1, 2, 3]; b = a.reject(&:odd?)`. Print `a` and `b`. Now try `a.reject!(&:odd?)` and print `a`.
3. Write `def twice = [yield, yield]` and call `twice { rand(10) }`.

### Check yourself
1. What does `moles.find { ... }` return if no mole contains the point? How does `whack_at` use that?
2. `points` has 33 entries in `Window#draw_hole`. How many triangles does `each_cons(2)` draw?
3. Why is `reject!` correct in `update_round` but `-` (non-mutating) correct for `free_holes`?

---

## Lesson 1.8: Modules, namespaces and files

### Objectives
- **[R1.18]** Use a module as a namespace and reach inside it with `::` (e.g. `Config::WIDTH`, `WhackTheMole::Game`).
- **[R1.19]** Load code with `require` and `require_relative`, and build file paths with `File.join`, `File.expand_path` and `__dir__`.

### Read
`lib/whack_the_mole.rb`, the top of `window.rb` and `high_score.rb`, `Config::ASSETS_DIR`, `Window#asset`, `test/test_helper.rb`.

### Concept
**Modules as namespaces.** Every file wraps its code in `module WhackTheMole ... end`, so the game's `Game`, `Score` and `Window` can't clash with a gem's class of the same name. Outside the module you write `WhackTheMole::Game`; inside it, plain `Game` works. `Config` is a module nested inside `WhackTheMole` that holds nothing but constants, so `Config::ROUND_MS` reads "the `ROUND_MS` constant in `Config`". Keeping every tunable number in one module means changing the round length is a one-line edit.

**Loading code.**
- `require 'json'` loads a library from Ruby's standard library or an installed gem, found by name.
- `require_relative 'whack_the_mole/config'` loads a file by path, relative to the file that's doing the requiring. Use it for your own project files.
- Each file is loaded once, even if required many times.

`lib/whack_the_mole.rb` requires every game-rules file, in an order where each file's dependencies come first. `window.rb` requires `gosu` and that file. Game rule files never require `gosu`, which is what lets the tests run without opening a window.

**Paths.** `__dir__` is the directory of the current file. `File.join('a', 'b.png')` joins parts with the right separator. `File.expand_path('../../assets', __dir__)` turns a relative path into an absolute one, starting from `config.rb`'s folder (`lib/whack_the_mole`), going up two levels to the repo root, then into `assets`. This way the game finds its images no matter which directory you launch it from.

### Try it
1. In `irb`: `require_relative 'lib/whack_the_mole'` (from the repo root), then `WhackTheMole::Config::GRID_LEFT` and `WhackTheMole::Hole.grid.size`.
2. `File.join('assets', 'mole-sheet.png')` and `File.expand_path('..', Dir.pwd)`.
3. Why does `test/test_helper.rb` use `require` for minitest but `require_relative` for the game?

### Check yourself
1. What does `Config::GRID_LEFT` evaluate to? Show the arithmetic.
2. What would break if `config.rb` built `ASSETS_DIR` as `'assets'` instead of with `expand_path`?
3. Why must `config.rb` be required before `hole.rb`?

---

## Phase 1 project: the Field Report

You'll write a script that prints a report about the game's world, using only the game's code and the ideas from this phase. No new classes.

**Create** `scripts/field_report.rb`. It must `require_relative '../lib/whack_the_mole'` and, when run with `bundle exec ruby scripts/field_report.rb`, print these four sections:

1. **Board.** Window size, grid size, and a line per hole: its number (1 to 9, in `Hole.grid` order) and its `x, y`.
2. **Map.** A text picture of the grid using `each_slice(Config::GRID_COLS)` (look it up: it's like `each_cons` but without overlap), with each hole shown as `[n]`.
3. **Difficulty ramp.** A table of the mole up-time at 0%, 25%, 50%, 75% and 100% of the round, computed with the same formula as `Game#spawn_mole` (`UP_MS_START + (UP_MS_END - UP_MS_START) * fraction`, rounded).
4. **Spawn simulation.** With `Random.new(seed)`, where `seed` is the first command-line argument (`ARGV.first`, default `42`), pick 1,000 random holes with `Hole.grid.sample(random:)`, and print how many times each hole was picked, using a Hash. Running twice with the same seed must print the same numbers.

**Done when** the output is correct, `bundle exec rubocop scripts/field_report.rb` is clean, and you can explain every line. The rubric is in the [phase 1 assessment](assessment.md), Part C.

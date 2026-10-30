# Phase 4: Ruby on Rails

**Driving question:** How do players compare scores across machines?

Right now your best score lives in one JSON file on one computer. In this phase you'll build a **leaderboard**: a Rails web app that stores everyone's scores in a database, accepts new scores from the game over HTTP, and shows the top ten as JSON (for the game) and as a web page (for people). Then you'll connect the game to it without ever freezing the game loop. The spec planned this as phase 2 of the product ("a leaderboard API that the game posts scores to").

Rails is a large framework. This phase teaches the core that every Rails app uses: the request cycle, routes, models, migrations, validations, controllers, views and tests. Keep the [Rails Guides](https://guides.rubyonrails.org/) open; the lessons tell you which guide to read for depth.

**Setup:** `gem install rails`, then check `rails -v` (8.x). On Windows, if `bin/rails ...` doesn't run in PowerShell, use `ruby bin/rails ...`.

The leaderboard is its own app. Create it next to the game, not inside it: `cd ..` from the game repo, then `rails new leaderboard --minimal`. Commit it to its own git repository.

---

## Lesson 4.1: HTTP and JSON

### Objectives
- **[W4.1]** Describe an HTTP request and response (method, path, headers, body, status code), choose GET vs POST, and read the status codes this app uses: 200, 201, 400, 404, 422, 429, 500.

### Read
MDN, "An overview of HTTP" (search for it). `lib/whack_the_mole/high_score.rb` again: you already know JSON.

### Concept
The web is requests and responses. A client (browser, or the game) sends a **request**; a server sends back a **response**.

```
POST /scores HTTP/1.1                          <- method and path
Host: localhost:3000
Content-Type: application/json                 <- headers: metadata
Accept: application/json

{"score":{"player_name":"AJ","points":12,"hits":15,"misses":3}}   <- body

HTTP/1.1 201 Created                           <- status code
Content-Type: application/json

{"id":7,"player_name":"AJ","points":12,...}
```

**Methods** say what you want. `GET` reads and must not change anything (browsers and caches may repeat it freely). `POST` creates something. (`PATCH`/`PUT` update and `DELETE` removes; this app doesn't need them.)

**Status codes** say what happened:

| Code | Meaning | In the leaderboard |
|---|---|---|
| 200 OK | Here's what you asked for | `GET /scores` |
| 201 Created | I made the thing | a valid `POST /scores` |
| 400 Bad Request | Your request is malformed | the JSON contains none of the score fields |
| 404 Not Found | No such path | a typo in the URL |
| 422 Unprocessable Content | Well-formed, but invalid | a blank name or negative hits |
| 429 Too Many Requests | Slow down | too many posts in a minute (final capstone) |
| 500 Internal Server Error | The server broke | a bug in your code |

2xx means success, 4xx means the *client* did something wrong, 5xx means the *server* did. A client can retry a 5xx later; retrying a 4xx unchanged will fail again.

**JSON** is the body format for both directions, just as with the high-score file. The `Content-Type: application/json` header tells the receiver how to read the body.

### Try it
1. With any server running later in this phase, run `curl -i http://localhost:3000/scores.json` and identify the status line, headers and body.
2. Write the request line and body a game would send to post a score of 4 (6 hits, 2 misses) for player "Mo".
3. Which status code fits each: a name 200 characters long; a server that crashed; the scores list?

### Check yourself
1. What's the difference between GET and POST, and why must GET not change data?
2. When should the server answer 422 rather than 400?
3. A client gets a 500. Is it the client's fault? Should it retry?

---

## Lesson 4.2: A Rails app and its routes

### Objectives
- **[W4.2]** Create a Rails app, run its server and console, and explain MVC and "convention over configuration" by finding where models, views, controllers, migrations and tests live.
- **[W4.3]** Define routes with `resources` and `root`, read `bin/rails routes`, and use the generated path and URL helpers.

### Read
Rails Guides: "Getting Started with Rails" (sections on creating the app, MVC, and routes) and "Rails Routing from the Outside In" (resource routing).

### Concept
```sh
rails new leaderboard --minimal   # a smaller app without features we don't need
cd leaderboard
bin/rails server                  # http://localhost:3000
bin/rails console                 # irb with the whole app loaded
```

**MVC** splits a web app like the game splits rules and window:

- **Model** (`app/models/`): the data and its rules. Talks to the database. Like `Score`, `Mole`.
- **View** (`app/views/`): turns data into HTML. Like `Window#draw`: shows, never decides.
- **Controller** (`app/controllers/`): receives a request, uses models, picks a response. Like `Window#button_down` calling `@game.click`.

**Convention over configuration.** Rails finds things by name. A request routed to `scores#index` runs `ScoresController#index` in `app/controllers/scores_controller.rb` and renders `app/views/scores/index.html.erb`. The `Score` model reads and writes the `scores` table. You write almost no wiring as long as you follow the naming.

Other folders: `db/migrate/` (database changes), `db/schema.rb` (current database shape, generated), `config/routes.rb` (URL → controller), `test/` (tests, Minitest, the same as the game).

**Routes** map a method and path to a controller action:

```ruby
Rails.application.routes.draw do
  resources :scores, only: %i[index create]
  root 'scores#index'
end
```

`resources :scores` follows REST conventions; `only:` keeps the two we need. `bin/rails routes` prints:

```
Prefix  Verb  URI Pattern        Controller#Action
scores  GET   /scores(.:format)  scores#index
        POST  /scores(.:format)  scores#create
  root  GET   /                  scores#index
```

The prefix gives you helpers: `scores_path` is `"/scores"`, `scores_url` is `"http://localhost:3000/scores"`. Use the helpers instead of typing paths. `(.:format)` means `/scores.json` asks for JSON.

### Try it
1. Create the app, start the server, open `http://localhost:3000`.
2. Add the routes above and run `bin/rails routes`. Then visit `/scores` and read the error (no controller yet). What's it looking for, by name?
3. In `bin/rails console`, run `app.scores_path` and `app.scores_url`.

### Check yourself
1. In MVC, which part is most like `Window#draw`, and which like `Game`?
2. Where does Rails look for the code and template for `scores#index`?
3. Which routes does `resources :scores` create without `only:`? Why limit them?

---

## Lesson 4.3: Models, migrations and validations

### Objectives
- **[W4.4]** Generate a model and migration, run migrations, explain `db/schema.rb`, and create, read and count records with Active Record in the console.
- **[W4.5]** Validate a model with built-in validations (`presence`, `length`, `numericality`) and a custom `validate` method, and read `valid?` and `errors`.

### Read
Rails Guides: "Active Record Basics", "Active Record Migrations" (overview), "Active Record Validations".

### Concept
```sh
bin/rails generate model Score player_name:string points:integer hits:integer misses:integer
bin/rails db:migrate
```

The generator makes four files: the model `app/models/score.rb`, a migration in `db/migrate/`, a model test, and fixtures (`test/fixtures/scores.yml`). The **migration** is a Ruby description of a database change:

```ruby
class CreateScores < ActiveRecord::Migration[8.1]
  def change
    create_table :scores do |t|
      t.string :player_name, null: false
      t.integer :points, null: false
      t.integer :hits, null: false
      t.integer :misses, null: false
      t.timestamps                       # created_at and updated_at
    end
  end
end
```

(Add the `null: false` parts yourself before migrating; the generator doesn't.) `db:migrate` runs pending migrations and rewrites `db/schema.rb`, the current shape of the database. Never edit a migration that has already run and been shared; write a new one.

**Active Record** gives the model class methods for the table, with no SQL:

```ruby
Score.create!(player_name: 'AJ', points: 12, hits: 15, misses: 3)  # insert; raises ActiveRecord::RecordInvalid if invalid
Score.create(player_name: '')        # if invalid: returns the record unsaved, raises nothing
Score.count
Score.first.player_name
Score.where(player_name: 'AJ')
score = Score.new(player_name: '')   # not saved yet
score.save                           # => false if invalid, true if saved
```

**Validations** stop bad data before it reaches the database. This is the same idea as `HighScore#load` checking the file's shape, at the boundary where untrusted data comes in:

```ruby
class Score < ApplicationRecord
  validates :player_name, presence: true, length: { maximum: 20 }
  validates :points, numericality: { only_integer: true }
  validates :hits, :misses, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :points_match_hits_and_misses

  private

  def points_match_hits_and_misses
    return if points.nil? || hits.nil? || misses.nil?

    errors.add(:points, 'must equal hits minus misses') unless points == hits - misses
  end
end
```

`score.valid?` runs them; `score.errors.full_messages` lists what failed, like `["Player name can't be blank"]`. The custom rule is game-specific: the game's rule is `total = hits - misses`, so a score that breaks it was invented, not played. Validations are your defense against bad clients.

### Try it
1. Generate the model, add `null: false`, migrate, and open `db/schema.rb`.
2. In the console, create a valid score; then try `Score.new(player_name: '', points: 5, hits: 1, misses: 0)` and print `valid?` and `errors.full_messages`.
3. What does `Score.create!(...)` do with invalid data, compared with `Score.create(...)`?

### Check yourself
1. What's the difference between a migration file and `db/schema.rb`?
2. Why validate in the model when the game will only ever send good data?
3. What's the difference between `save` and `save!`?

---

## Lesson 4.4: Querying

### Objectives
- **[W4.6]** Query with `where`, `order`, `limit` and ranges, and package reusable queries as scopes that chain.

### Read
Rails Guides: "Active Record Query Interface" (conditions, ordering, limit, scopes).

### Concept
Queries are built lazily from chained calls and only run when you use the results:

```ruby
Score.order(points: :desc).limit(10)                 # the top ten
Score.where(player_name: 'AJ').order(created_at: :desc)
Score.where(created_at: 1.day.ago..)                 # created in the last day (endless range)
Score.where(points: 10..20)                          # between 10 and 20 inclusive
```

Each call returns a *relation* you can keep chaining. `.to_sql` shows the SQL it'll run.

**Ties.** Two players with 15 points: who's first? Without a second sort key the database can return them in any order, and the leaderboard might shuffle between page loads. Order by points, then by who got there first: `order(points: :desc, created_at: :asc)`.

**Scopes** name a query so it reads like the domain:

```ruby
class Score < ApplicationRecord
  scope :top, -> { order(points: :desc, created_at: :asc).limit(10) }
  scope :since, ->(time) { where(created_at: time..) }
end

Score.top               # the all-time top ten
Score.since(1.day.ago)  # chains: Score.since(1.day.ago).top
```

`-> { ... }` is a **lambda**: a block you can store and call later. Scopes use it so the query is built when you *call* the scope, not once when the class loads (which matters for `1.day.ago`).

### Try it
1. Create five scores in the console, two of them tied, and compare `Score.order(points: :desc)` with the tie-broken version.
2. Add both scopes and try `Score.since(1.hour.ago).top.to_sql`.
3. Why would `scope :today, where(created_at: Time.current.all_day)` (no lambda) be wrong even if Rails allowed it?

### Check yourself
1. Why does the top-ten scope need a second sort key?
2. What does `Score.since(1.day.ago).top` return?
3. When does a relation actually query the database?

---

## Lesson 4.5: Controllers and a JSON API

### Objectives
- **[W4.7]** Write controller actions that read params, use strong parameters (`params.expect`), and render JSON with the right status codes for success and validation failure.

### Read
Rails Guides: "Action Controller Overview" (parameters, strong parameters, rendering). Your `config/routes.rb`.

### Concept
```ruby
class ScoresController < ApplicationController
  def index
    render json: Score.top.as_json(only: %i[player_name points hits misses created_at])
  end

  def create
    score = Score.new(score_params)
    if score.save
      render json: score, status: :created
    else
      render json: { errors: score.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def score_params
    params.expect(score: %i[player_name points hits misses])
  end
end
```

**Params.** Rails collects the JSON body (and query string) into `params`. The game sends `{"score": {...}}`, so the fields are under `params[:score]`.

**Strong parameters.** `params.expect(score: [...])` says "there must be a `score` hash, and only these keys may pass through". Anything else (`id`, `created_at`, a made-up `admin` field) is dropped. Without this, `Score.new(params[:score])` would let a client set any column: that's called **mass assignment**, and Rails refuses unpermitted params for that reason. If `score` is missing or empty, `expect` raises and Rails answers **400**.

**Parameter wrapping.** Rails has one convenience that surprises people: for JSON requests it *wraps* the body for you. If a client posts `{"player_name": "AJ", "points": 2, ...}` without the `score` key, Rails copies any keys that match `Score`'s columns into `params[:score]`, so the request still works. A 400 only happens when none of the score fields are there, for example a body of `{}` or `{"name": "AJ"}`, or a request that isn't sent as JSON at all. Send the `score` wrapper anyway: it's explicit, and it works whatever the server's settings.

**Responding.** `status: :created` is 201; `:unprocessable_content` is 422 (older code says `:unprocessable_entity`). Return the errors so the client can show or log them. `as_json(only: ...)` picks the fields to expose: the client doesn't need `id` or `updated_at`.

Keep controllers thin, like `Window`: read the request, call the model, choose a response. The rules (what's a valid score, what's the top ten) live in the model, where they're easy to test.

### Try it
1. Write the controller and post a score with curl:
   `curl -i -X POST localhost:3000/scores -H "Content-Type: application/json" -d '{"score":{"player_name":"AJ","points":2,"hits":3,"misses":1}}'`
   (In PowerShell, use `curl.exe` and escape the quotes, or test from the console in lesson 4.7 instead.)
2. Post one with `"points":99`. What status and body come back?
3. Post `{"player_name":"AJ"}` without the `score` wrapper. What status, and why not 400? Then post `{"name":"AJ"}`.

### Check yourself
1. What two jobs does `params.expect` do?
2. Why respond 422 with the error messages instead of 200 with `{"ok": false}`?
3. What would go wrong with `Score.new(params[:score].to_unsafe_h)`?

---

## Lesson 4.6: Views and formats

### Objectives
- **[W4.8]** Render an HTML page with an ERB template and a layout, serve HTML and JSON from one action with `respond_to`, and explain why ERB escapes output by default.

### Read
Rails Guides: "Layouts and Rendering in Rails" (the overview and `respond_to`), "Action View Overview" (ERB). The "Cross-Site Scripting" section of the "Securing Rails Applications" guide.

### Concept
**ERB** templates are HTML with Ruby in them. `<% %>` runs Ruby; `<%= %>` runs it and inserts the result:

```erb
<h1>Top ten</h1>
<table>
  <tr><th>#</th><th>Player</th><th>Score</th><th>Hits</th><th>Misses</th></tr>
  <% @scores.each_with_index do |score, i| %>
    <tr>
      <td><%= i + 1 %></td>
      <td><%= score.player_name %></td>
      <td><%= score.points %></td>
      <td><%= score.hits %></td>
      <td><%= score.misses %></td>
    </tr>
  <% end %>
</table>
```

That's `app/views/scores/index.html.erb`. The controller passes data through **instance variables**: `@scores` set in the action is visible in its template. The template is wrapped in `app/views/layouts/application.html.erb`, which holds the shared `<html>`, `<head>` and `<body>`; `<%= yield %>` marks where each page goes (the same `yield` as phase 1).

**One action, two formats:**

```ruby
def index
  @scores = Score.top
  respond_to do |format|
    format.html
    format.json { render json: @scores.as_json(only: %i[player_name points hits misses created_at]) }
  end
end
```

A browser asking for `/scores` gets HTML; the game asking for `/scores.json` (or sending `Accept: application/json`) gets JSON. Same data, same query, two views of it.

**Escaping (XSS).** Player names come from clients. If someone posts the name `<script>steal()</script>` and the page inserted it raw, every visitor's browser would run that script: **cross-site scripting**. `<%= %>` escapes HTML automatically, so the name shows as harmless text. Never use `raw` or `.html_safe` on user data.

### Try it
1. Build the template and visit `/scores` in a browser with a few scores in the database.
2. Post a score whose name is `<b>bold</b>` and view the page. Then view the page source.
3. Visit `/scores.json` and `/scores` and confirm both work.

### Check yourself
1. What's the difference between `<% %>` and `<%= %>`?
2. How does `@scores` get from the controller to the template?
3. What would happen if the template used `<%= raw score.player_name %>`?

---

## Lesson 4.7: Testing Rails

### Objectives
- **[W4.9]** Test a Rails app with Minitest: model tests for validations and scopes, fixtures, and integration tests that make requests and assert on status and JSON.

### Read
Rails Guides: "Testing Rails Applications" (model tests, fixtures, integration tests). `test/` in your app.

### Concept
Rails tests are Minitest, as in the game, with extra helpers. `bin/rails test` runs them all against a separate test database that's reset each run.

**Fixtures** (`test/fixtures/scores.yml`) are sample rows loaded before every test:

```yaml
ace:
  player_name: Ace
  points: 20
  hits: 22
  misses: 2
rookie:
  player_name: Rookie
  points: 1
  hits: 3
  misses: 2
```

`scores(:ace)` returns that record in a test.

**Model tests** check validations and scopes directly:

```ruby
class ScoreTest < ActiveSupport::TestCase
  test 'points must equal hits minus misses' do
    score = Score.new(player_name: 'AJ', points: 9, hits: 3, misses: 1)

    assert_not score.valid?
    assert_includes score.errors[:points], 'must equal hits minus misses'
  end
end
```

`test 'name' do ... end` is Rails shorthand for `def test_name`. `assert_not` is Rails' `refute`.

**Integration tests** go through routing, the controller and the model, like a real client:

```ruby
class ScoresTest < ActionDispatch::IntegrationTest
  test 'creates a valid score' do
    assert_difference('Score.count', 1) do
      post scores_url, params: { score: { player_name: 'AJ', points: 2, hits: 3, misses: 1 } }, as: :json
    end

    assert_response :created
    assert_equal 'AJ', response.parsed_body['player_name']
  end
end
```

`as: :json` sends the params as a JSON body, exactly what the game will do. `assert_difference` checks a count changed by exactly that much; `assert_no_difference` checks it didn't. `response.parsed_body` decodes the JSON.

Test the edges, as you did in the game: the boundary values (20 characters vs 21), missing fields, invalid combinations, ties in the ranking, and that `index` returns at most ten.

### Try it
1. Write the fixtures above and a test that `Score.top.first` is `scores(:ace)`.
2. Write an integration test that posting a blank name returns 422 and creates nothing.
3. Run one test file: `bin/rails test test/models/score_test.rb`.

### Check yourself
1. What's a fixture, and when is it loaded?
2. What does an integration test cover that a model test doesn't?
3. Why use `assert_no_difference('Score.count')` in the invalid-post test?

---

## Lesson 4.8: Security basics

### Objectives
- **[W4.10]** Apply the core web security rules to this app: never trust the client (validate and permit), escape output, understand CSRF protection and when an API endpoint can skip it, and limit abuse with rate limiting.

### Read
Rails Guides: "Securing Rails Applications" (CSRF, mass assignment, injection, XSS). Rails API docs for `rate_limit`.

### Concept
Your server is on a network; anyone can send it anything, not just your game. Every rule comes from that.

1. **Never trust the client.** The game is open source; someone will post `{"points": 1000000}`. Strong params limit *which* fields; validations check *what values*; the hits-minus-misses rule makes impossible scores fail. (A determined cheater can still invent consistent numbers; real anti-cheat is beyond this course. Know the limits of your defenses.)
2. **Don't build SQL from strings.** `Score.where("player_name = '#{name}'")` lets a crafted name rewrite the query (**SQL injection**). Use hash conditions or placeholders: `where(player_name: name)` or `where('points > ?', n)`.
3. **Escape output.** ERB does it (lesson 4.6). Don't bypass it.
4. **CSRF.** A browser automatically sends its cookies to your site, even when a *different* site's page triggers the request. Cross-site request forgery abuses that: an evil page could make your logged-in browser post to your bank. Rails blocks it by requiring a secret token on non-GET requests from forms, which other sites can't read. The game isn't a browser and our endpoint uses no cookies or login, so there's nothing to forge; the token requirement would only block the game. So the API action opts out explicitly:

   ```ruby
   skip_forgery_protection only: :create
   ```

   In the test environment Rails turns CSRF checks off, so **your tests pass either way**. Only real requests reveal the problem. Remember that when the game gets a 422 your tests never saw.
5. **Rate limiting.** One client posting a thousand scores a second floods the board. Rails 8 has it built in:

   ```ruby
   rate_limit to: 10, within: 1.minute, only: :create
   ```

   Over the limit, Rails answers 429. It counts requests in the app's cache store; the test environment's default store (`:null_store`) remembers nothing, so to *test* it, pass a real store such as `store: ActiveSupport::Cache::MemoryStore.new` (see the `rate_limit` API docs).

### Try it
1. Start the server and post a score with curl *without* `skip_forgery_protection`. What happens? Add it and try again.
2. In the console, compare `Score.where(player_name: "x' OR '1'='1").to_sql` with the string-interpolated version.
3. Add the rate limit and post 11 times quickly with curl in a loop.

### Check yourself
1. Name three things a malicious client could send and the defense for each.
2. Why can `create` skip CSRF protection here, and why wouldn't that be safe for a form behind a login?
3. Why do the integration tests pass even without `skip_forgery_protection`?

---

## Lesson 4.9: Connecting the game

### Objectives
- **[W4.11]** Call the API from Ruby with `Net::HTTP`, inject the HTTP transport for testing, handle network failure without crashing, and keep the game loop responsive by doing network work on a background thread.

### Read
Ruby docs for `Net::HTTP` (`post`, `get_response`, `start` with timeouts) and `Thread` and `Thread::Queue`. Your phase 2 notes on dependency injection and duck typing.

### Concept
The game needs a client: plain Ruby, in `lib/whack_the_mole/leaderboard_client.rb`, no `gosu` (rules layer).

```ruby
require 'json'
require 'net/http'

module WhackTheMole
  class LeaderboardClient
    NETWORK_ERRORS = [SystemCallError, SocketError, Timeout::Error].freeze

    def initialize(base_url:, transport: Net::HTTP)
      @base_url = base_url
      @transport = transport
    end

    def submit(player_name, score)
      body = { score: { player_name:, points: score.total, hits: score.hits, misses: score.misses } }
      response = @transport.post(URI("#{@base_url}/scores"), JSON.generate(body), 'Content-Type' => 'application/json')
      response.code == '201' ? :ok : :rejected
    rescue *NETWORK_ERRORS
      :offline
    end
  end
end
```

- **Transport injection.** `Net::HTTP.post(uri, body, headers)` and `Net::HTTP.get_response(uri)` are class methods, so the class itself can be the default transport. In tests, pass any object with the same methods (duck typing, phase 2) that records the request and returns a fake response with `code` and `body`. No server needed; tests stay fast and deterministic.
- **Failure is normal.** The server may be down or the Wi-Fi off. Connection refused is a `SystemCallError`; an unknown host is a `SocketError`; a slow server ends in a `Timeout::Error`. Rescue exactly those (not everything) and return a value the game can show ("offline"). Like the sound files: the leaderboard is optional; the game must work without it.
- **Response codes are strings** in `Net::HTTP`: `response.code == '201'`.
- **Base URL from the environment.** `ENV.fetch('LEADERBOARD_URL', 'http://localhost:3000')` keeps the address out of the code.

**Never block the game loop.** A request can take seconds (`Net::HTTP` waits up to 60 seconds by default for a slow server). If `Window#update` waited for it, the game would freeze: no drawing, no input. Run it on a **thread**, a second line of execution that runs alongside the loop:

```ruby
@results = Thread::Queue.new
Thread.new { @results << client.submit(name, score) }   # returns immediately

# later, in update: check without waiting
@leaderboard_status = @results.pop(true) unless @results.empty?
```

`Thread::Queue` is a thread-safe mailbox: the background thread puts the result in; the game loop takes it out when it's there, and never waits. Only the main thread touches game and window state; the background thread only talks to the network and the queue. That one rule avoids most threading bugs.

To bound the wait, use the longer form with timeouts: `Net::HTTP.start(uri.host, uri.port, open_timeout: 2, read_timeout: 2) { |http| http.post(uri.path, body, headers) }`.

### Try it
1. Write the client, then in `irb` with the Rails server running, submit a `Score` and check `/scores` in the browser.
2. Stop the server and submit again. What does `submit` return?
3. Write a fake transport class with `post(uri, body, headers)` that records its arguments and returns `Struct.new(:code, :body).new('201', '{}')`.

### Check yourself
1. Why does `submit` rescue three specific error classes instead of `StandardError`?
2. What would the player see if `submit` were called directly in `update` and the server took 5 seconds?
3. Why does only the main thread change game state?

---

## Phase 4 project: the online leaderboard

Build the leaderboard app and connect the game to it.

**The Rails app** (`leaderboard`, its own repository):
1. `Score` model with `player_name`, `points`, `hits`, `misses`, timestamps, `null: false` on the four fields, the validations from lesson 4.3, and the `top` and `since` scopes.
2. `GET /scores` (HTML, the root page) and `GET /scores.json` show the top ten. `POST /scores` (JSON) creates a score: 201 with the score, 422 with error messages, 400 if no score fields are sent. CSRF skipped for `create` only.
3. Fixtures and tests: model tests for every validation (including boundaries) and both scopes; integration tests for every status code above and that only permitted fields are saved.

**The game** (branch `phase-4-leaderboard`):
4. `LeaderboardClient` with `submit` and `top` (returns an array of hashes, or `[]` when offline or on any non-200), transport injected, tested with a fake transport.
5. At game over, the window submits the score on a background thread under the name in `ENV['PLAYER_NAME']` (default `"Player"`), and the game-over screen shows `Leaderboard: sent`, `rejected` or `offline` once the result arrives (`sending...` until then). The game never freezes, with or without the server.
6. All game checks pass (`rake test`, `rubocop`, smoke launch), and `bin/rails test` passes in the app.

The rubric is in the [phase 4 assessment](assessment.md), Part C.

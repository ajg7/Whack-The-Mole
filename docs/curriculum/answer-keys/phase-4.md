# Phase 4 answer key

Don't open this until you've written every Part A answer. An answer earns the point if it states the key idea, even in different words.

## Part A

### Q1
(a) 200 (b) 201 (c) 422 (d) 400: `name` isn't a score column, so parameter wrapping finds no score fields (e) 429 (f) 500. Half a point each.

### Q2
`POST` creates data; `GET` only reads it and must be safe to repeat (1 pt). With a `GET`, browsers, link previews, crawlers and caches may repeat or prefetch it, creating duplicate or unintended scores; a link on any page could submit one (1 pt).

### Q3
(a) Views ≈ `Window#draw` (show, don't decide); models ≈ `Game`'s rules (1 pt). (b) `ScoresController#index` in `app/controllers/scores_controller.rb`, rendering `app/views/scores/index.html.erb` (1 pt).

### Q4
`GET /scores → scores#index`, `POST /scores → scores#create`, `GET / → scores#index` (1 pt). `scores_path` is `"/scores"` (1 pt).

### Q5
(a) A migration is one change, written as Ruby, applied once in order; `schema.rb` is generated: the current shape of the whole database (1 pt). (b) Generate a new migration (e.g. `bin/rails generate migration AddLevelToScores level:integer`) and run it; never edit a migration others have already run (1 pt).

### Q6
`1`, `1`, `1` (1 pt: `create` returns an unsaved invalid record; `new` doesn't save). The last line raises `ActiveRecord::RecordInvalid` and the count stays 1 (1 pt).

### Q7
(a) Valid. (b) Valid: negative totals are allowed and −2 = 1 − 3. (c) Invalid: `player_name` length maximum 20. (d) Invalid: `misses` must be ≥ 0 (even though 5 = 4 − (−1)). 1 pt each.

### Q8
Anyone can send requests to the server, not just the game: validations are the defense at the trust boundary.

### Q9
`scope :top, -> { order(points: :desc, created_at: :asc).limit(10) }` (1 pt). The lambda is called each time the scope is used, so the query (and anything time-based in it) is built fresh, not once when the class loads (1 pt).

### Q10
`["Late", "Rookie"]` (1 pt). `since` keeps scores created in the last 36 hours (Late at 1 day ago, Rookie now; Early and Ace are older); `top` orders by points, 5 before 1 (1 pt).

### Q11
(a) Requires a non-empty `score` hash (400 if missing, after Rails' JSON parameter wrapping) and permits only the listed keys (1 pt). (b) `id` is filtered out and ignored; the database assigns the id (1 pt).

### Q12
`save`, `:created`, `full_messages`, `:unprocessable_content` (or `:unprocessable_entity`). Half a point each.

### Q13
(a) `<% %>` runs Ruby without output; `<%= %>` runs it and inserts the (escaped) result (1 pt). (b) The script would run in every visitor's browser: cross-site scripting (1 pt). (c) Serve different formats (HTML for browsers, JSON for the game) from the same action and data (1 pt).

### Q14
```ruby
test 'rejects a blank name' do
  assert_no_difference('Score.count') do
    post scores_url, params: { score: { player_name: '', points: 1, hits: 1, misses: 0 } }, as: :json
  end

  assert_response :unprocessable_content
end
```
1 pt for the request with `as: :json`, 1 pt for `assert_no_difference`, 1 pt for the status assertion.

### Q15
(a) Sample database rows defined in `test/fixtures/*.yml`, loaded fresh before each test (1 pt). (b) Any one: routing, params parsing and strong params, the status code, the JSON or HTML response, CSRF behavior (1 pt).

### Q16
The second line (1 pt): interpolating input into SQL allows SQL injection, e.g. a name like `x' OR '1'='1`. Safe: the first line, or `Score.where('player_name = ?', params[:name])` (1 pt).

### Q17
(a) CSRF abuses a browser's automatically-sent cookies; this endpoint uses no cookies, sessions or login, so there's no authority to hijack. A form behind a login relies on cookies and needs the token (1 pt). (b) The test environment sets `allow_forgery_protection = false` (1 pt).

### Q18
`429 Too Many Requests` (1 pt). The limit is counted in the cache store, and the test environment uses `:null_store`, which stores nothing (1 pt).

### Q19
A request can take seconds; the game loop must keep updating and drawing every ~16 ms (1 pt). The game would freeze for 5 seconds: no drawing, no hammer movement, clicks ignored or delayed, then everything jumps (1 pt).

### Q20
(a) `SystemCallError` (e.g. connection refused), `SocketError` (unknown host), `Timeout::Error` (slow server). `StandardError` would also swallow bugs like a `NoMethodError` (1 pt). (b) `Net::HTTP` responses report `code` as a String (1 pt).

### Q21
The transport is injected (dependency injection) and the tests pass a fake object with the same `post`/`get_response` methods (duck typing) that records requests and returns canned responses or raises chosen errors (2 pts: 1 for how, 1 for naming the ideas).

## Part B

- B2 reference solution: [phase4_leaderboard_client.rb](phase4_leaderboard_client.rb).
- B1 reference app files: [phase4_rails/](phase4_rails/) (model, controller, routes, view, migration). Notes:
  - The `points must equal hits minus misses` check skips itself when a field is missing, so the presence/numericality errors show instead of a confusing extra one.
  - `hits: 2.5` fails `only_integer` because Rails checks the value *before* it's cast to an integer column.
  - The forgery-protection test turns protection on for one request; it only passes with `skip_forgery_protection only: :create`.

# Phase 4 summative assessment: Ruby on Rails

Pass all three parts to unlock the final. See [the README](../README.md#passing-a-gate) for the rules.

The questions assume the `Score` model, routes and controller built in the [phase 4 lessons](lessons.md), and the fixtures in [practical/rails/fixtures/scores.yml](practical/rails/fixtures/scores.yml).

---

## Part A: written (closed-book, 46 points, pass at 37)

Write your answers in `practice/phase4/answers.md`.

### Q1 (3 pts)
Give the status code the leaderboard should return for each. (Half a point each.)

(a) `GET /scores.json` succeeds. (b) A valid score is posted. (c) A score with a blank name is posted. (d) The JSON body is `{"name": "AJ"}`. (e) A client has posted 50 times in a minute (with rate limiting on). (f) The controller has a typo that raises `NoMethodError`.

_Covers: W4.1_

### Q2 (2 pts)
Why is submitting a score a `POST` and reading the leaderboard a `GET`? What could go wrong if creating a score were done with a `GET`?

_Covers: W4.1_

### Q3 (2 pts)
(a) In MVC, which part of a Rails app plays the role of `Window#draw`, and which plays the role of `Game`'s rules? (b) A request is routed to `scores#index`. Which class and method run, in which file, and which template is rendered by default?

_Covers: W4.2_

### Q4 (2 pts)
```ruby
Rails.application.routes.draw do
  resources :scores, only: %i[index create]
  root 'scores#index'
end
```
List each route as `VERB /path → controller#action`, and give the value of `scores_path`.

_Covers: W4.3_

### Q5 (2 pts)
(a) What's the difference between a file in `db/migrate/` and `db/schema.rb`? (b) Your teammate already ran your `CreateScores` migration. You now need a `level` column. What do you do?

_Covers: W4.4_

### Q6 (2 pts)
Starting with an empty `scores` table, give `Score.count` after each line, and say what the last line does.

```ruby
Score.create!(player_name: 'Mo', points: 1, hits: 1, misses: 0)
Score.create(player_name: '', points: 1, hits: 1, misses: 0)
Score.new(player_name: 'Jo', points: 1, hits: 1, misses: 0)
Score.create!(player_name: '', points: 1, hits: 1, misses: 0)
```

_Covers: W4.4_

### Q7 (4 pts)
Valid or invalid? If invalid, which validation fails?

(a) `player_name: 'Mo', points: 0, hits: 0, misses: 0`
(b) `player_name: 'Mo', points: -2, hits: 1, misses: 3`
(c) `player_name: 'a' * 21, points: 1, hits: 1, misses: 0`
(d) `player_name: 'Mo', points: 5, hits: 4, misses: -1`

_Covers: W4.5_

### Q8 (1 pt)
The game always sends consistent scores. Why validate on the server anyway?

_Covers: W4.5, W4.10_

### Q9 (2 pts)
Write the `top` scope (best ten, ties broken by who scored first). Why is a scope's body written as a lambda (`-> { ... }`)?

_Covers: W4.6_

### Q10 (2 pts)
With only the four fixtures in the database, what does `Score.since(36.hours.ago).top.map(&:player_name)` return? Explain the order.

_Covers: W4.6_

### Q11 (2 pts)
(a) Name the two jobs `params.expect(score: %i[player_name points hits misses])` does. (b) A client posts `{"score": {"player_name": "AJ", "points": 2, "hits": 3, "misses": 1, "id": 1}}`. What happens to `id`?

_Covers: W4.7_

### Q12 (2 pts)
Fill in the blanks.

```ruby
def create
  score = Score.new(score_params)
  if score.____
    render json: score, status: ____
  else
    render json: { errors: score.errors.____ }, status: ____
  end
end
```

_Covers: W4.7_

### Q13 (3 pts)
(a) What's the difference between `<% %>` and `<%= %>` in ERB? (b) What would happen if the template used `<%= raw score.player_name %>` and someone posted the name `<script>alert(1)</script>`? (c) What does `respond_to` let one `index` action do?

_Covers: W4.8, W4.10_

### Q14 (3 pts)
Write an integration test (code) that posts a score with a blank name as JSON and checks that the response is 422 and no score was created.

_Covers: W4.9_

### Q15 (2 pts)
(a) What is a fixture, and when is it loaded? (b) Name one thing an integration test checks that a model test can't.

_Covers: W4.9_

### Q16 (2 pts)
Which line is unsafe, and why? Rewrite it safely.

```ruby
Score.where(player_name: params[:name])
Score.where("player_name = '#{params[:name]}'")
```

_Covers: W4.10_

### Q17 (2 pts)
(a) Why is `skip_forgery_protection only: :create` acceptable for this API, when it wouldn't be for a form behind a login? (b) Why do the integration tests pass even if you forget it?

_Covers: W4.10_

### Q18 (2 pts)
With `rate_limit to: 10, within: 1.minute, only: :create`, what does the 11th post in a minute get? Why does that limit never trigger in a default test environment?

_Covers: W4.10_

### Q19 (2 pts)
Why does the game submit its score on a background thread? Describe what the player would experience if `submit` ran directly inside `Window#update` and the server took 5 seconds to answer.

_Covers: W4.11, G3.1_

### Q20 (2 pts)
(a) Which exception classes should `LeaderboardClient#submit` rescue, and why not `StandardError`? (b) Why does it compare `response.code == '201'` with a string?

_Covers: W4.11, O2.9_

### Q21 (2 pts)
How do the client's tests check `submit` and `top` without a running server? Name the phase 2 ideas that make it possible.

_Covers: W4.11, O2.7, O2.8_

---

## Part B: practical (open-book, autograded)

**B1. The Rails app.** In your `leaderboard` app:

1. Copy [practical/rails/fixtures/scores.yml](practical/rails/fixtures/scores.yml) to `test/fixtures/scores.yml`, [practical/rails/models/score_test.rb](practical/rails/models/score_test.rb) to `test/models/score_test.rb`, and [practical/rails/integration/scores_test.rb](practical/rails/integration/scores_test.rb) to `test/integration/scores_test.rb`. Don't edit them.
2. Pass when `bin/rails test` reports 0 failures and 0 errors.

**B2. The game client.**

1. Copy [practical/client/leaderboard_client_test.rb](practical/client/leaderboard_client_test.rb) to `practice/phase4/leaderboard_client_test.rb`.
2. Write `practice/phase4/leaderboard_client.rb` (a top-level `LeaderboardClient` class) to make it pass, with `ruby practice/phase4/leaderboard_client_test.rb` and a clean `bundle exec rubocop practice/phase4`. You'll move it into `lib/whack_the_mole/` for the project.

| Tested behavior | Objectives |
|---|---|
| Model validations, boundaries, custom rule | W4.4, W4.5, W4.9 |
| `top` and `since` scopes, tie-break | W4.6 |
| `POST /scores`: 201, 422 with errors, 400, permitted fields only | W4.1, W4.3, W4.7 |
| `GET /scores.json` fields, root HTML page, escaping | W4.7, W4.8 |
| Posting works with forgery protection on | W4.10 |
| Client: JSON post, status handling, network errors, no hidden bugs | W4.11, O2.9 |
| Client: `top` parsing and fallbacks | W4.11, O2.10 |
| Client: `submit_async` returns at once and delivers through a queue | W4.11 |

---

## Part C: project (the online leaderboard)

Graded against your `leaderboard` repository and your game's `phase-4-leaderboard` branch. Every row must be **Meets** or **Exceeds**.

| Criterion | Below | Meets | Exceeds |
|---|---|---|---|
| API behavior | A route or status from the project spec is missing or wrong | Every route and status works, verified with curl or the browser, not only tests | Errors are consistent JSON for 400 as well as 422 |
| Model and data | Missing validations or `null: false`; untie-broken ranking | All validations, constraints, scopes and the tie-break in place | Database constraints mirror validations (e.g. a check constraint for non-negative hits) |
| Security | Unpermitted fields saved, raw output, or string-built SQL | Strong params, escaped output, CSRF skipped for `create` only, no string SQL | Rate limiting on `create`, with a test using a memory store |
| Tests | Status codes or validations untested | Model and integration tests cover every validation, boundary and status code | Tests also cover the `since` scope boundaries and the 10-row limit |
| Game integration | Game freezes without the server, or rules leak into the window | Background thread and queue; "sending... / sent / rejected / offline" shown; game works with the server off | Game-over screen also shows the top five from `top`, fetched in the background |
| Quality gate | Any check fails | Game: `rake test`, `rubocop`, smoke launch. App: `bin/rails test` | |

# frozen_string_literal: true

require 'test_helper'

class ScoresTest < ActionDispatch::IntegrationTest
  def post_score(**score)
    post scores_url, params: { score: }, as: :json
  end

  test 'creates a valid score' do
    assert_difference('Score.count', 1) do
      post_score(player_name: 'AJ', points: 2, hits: 3, misses: 1)
    end

    assert_response :created
    assert_equal 'AJ', response.parsed_body['player_name']
  end

  test 'rejects an invalid score with its errors' do
    assert_no_difference('Score.count') do
      post_score(player_name: '', points: 2, hits: 3, misses: 1)
    end

    assert_response :unprocessable_content
    assert_includes response.parsed_body['errors'], "Player name can't be blank"
  end

  test 'a body without any score fields is a bad request' do
    post scores_url, params: { name: 'AJ' }, as: :json

    assert_response :bad_request
  end

  test 'only permitted fields are saved' do
    post_score(player_name: 'AJ', points: 2, hits: 3, misses: 1, created_at: '2000-01-01')

    assert_response :created
    assert_operator Score.find_by(player_name: 'AJ').created_at, :>, 1.day.ago
  end

  test 'json index lists the top scores with only public fields' do
    get scores_url(format: :json)

    assert_response :ok
    assert_equal %w[Ace Early Late Rookie], response.parsed_body.pluck('player_name')
    assert_equal %w[created_at hits misses player_name points], response.parsed_body.first.keys.sort
  end

  test 'html index is the root page and escapes player names' do
    Score.create!(player_name: '<b>x</b>', points: 30, hits: 30, misses: 0)
    get root_url

    assert_response :ok
    assert_includes response.body, '&lt;b&gt;x&lt;/b&gt;'
    assert_select 'td', 'Ace'
  end

  test 'the game can post even with forgery protection on' do
    ActionController::Base.allow_forgery_protection = true
    post_score(player_name: 'AJ', points: 2, hits: 3, misses: 1)

    assert_response :created
  ensure
    ActionController::Base.allow_forgery_protection = false
  end
end

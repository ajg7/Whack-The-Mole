# frozen_string_literal: true

class ScoresController < ApplicationController
  skip_forgery_protection only: :create

  def index
    @scores = Score.top
    respond_to do |format|
      format.html
      format.json { render json: @scores.as_json(only: %i[player_name points hits misses created_at]) }
    end
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

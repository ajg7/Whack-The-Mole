# frozen_string_literal: true

Rails.application.routes.draw do
  resources :scores, only: %i[index create]
  root 'scores#index'
end

Rails.application.routes.draw do
  devise_for :users

  # Telegram webhook (unauthenticated API endpoint)
  namespace :telegram do
    post "webhook(/:token)", to: "webhooks#create", as: :webhook
  end

  # Sidekiq monitoring (admin only in production)
  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"

  # Authenticated app routes
  get "overview", to: "dashboard#show"
  get "dashboard", to: redirect("/overview")
  get "calendar", to: "calendar#show"
  get "insights", to: "insights#show"
  resource :onboarding, only: [:show, :update], controller: "onboarding"
  resource :settings, only: [:show, :update], controller: "settings"
  resources :content_drafts, only: [:index, :show]

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Landing page
  root "pages#home"
end

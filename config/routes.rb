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
  get "dashboard", to: "dashboard#show"
  get "overview", to: redirect("/dashboard")
  resource :strategy, only: [:show, :update], controller: "strategy"
  resource :planification, only: [:show], controller: "planification"
  get "calendar", to: "calendar#show"
  get "insights", to: redirect("/dashboard")
  resource :ai_manager, path: "ai-manager", only: [:show, :update], controller: "ai_manager"
  get "social_accounts/:provider/connect", to: "social_accounts#connect", as: :connect_social_account
  get "social_accounts/:provider/callback", to: "social_accounts#callback", as: :social_account_callback
  delete "social_accounts/:provider", to: "social_accounts#destroy", as: :disconnect_social_account
  resource :onboarding, only: [:show, :update], controller: "onboarding"
  resource :settings, path: "configuration", only: [:show, :update], controller: "settings"
  get "settings", to: redirect("/configuration")
  resources :campaign_plans, only: [:create, :update]
  resources :content_drafts, only: [:index, :show, :update] do
    post :publish, on: :member
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Landing page
  root "pages#home"
end

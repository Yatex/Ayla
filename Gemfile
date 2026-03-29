source "https://rubygems.org"

ruby "3.0.3"

gem "rails", "~> 7.1.6"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "tailwindcss-rails"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]

# Authentication
gem "devise"

# Background jobs
gem "sidekiq"
gem "redis"

# Telegram Bot API
gem "telegram-bot-ruby"

# HTTP client (for external API calls)
gem "faraday"

# Environment variables
gem "dotenv-rails"

# JSON serialization
gem "jsonb_accessor"

# State machines for models
gem "aasm"

group :development, :test do
  gem "debug", platforms: %i[ mri mswin mswin64 mingw x64_mingw ]
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "web-console"
  gem "annotate"
end


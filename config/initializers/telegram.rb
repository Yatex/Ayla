Rails.application.config.telegram = ActiveSupport::OrderedOptions.new
Rails.application.config.telegram.bot_token = ENV.fetch("TELEGRAM_BOT_TOKEN", "")
Rails.application.config.telegram.bot_username = ENV.fetch("TELEGRAM_BOT_USERNAME", "").delete_prefix("@")
Rails.application.config.telegram.webhook_secret = ENV.fetch("TELEGRAM_WEBHOOK_SECRET", "")

module Telegram
  class WebhooksController < ActionController::API
    before_action :verify_webhook_token

    def create
      Telegram::ProcessWebhookJob.perform_later(webhook_params)
      head :ok
    end

    private

    def verify_webhook_token
      expected = Rails.application.config.telegram.webhook_secret
      return if expected.blank? # Skip verification in dev if not configured

      token = params[:token] || request.headers["X-Telegram-Bot-Api-Secret-Token"]
      head :unauthorized unless token == expected
    end

    def webhook_params
      params.except(:controller, :action, :token).permit!.to_h
    end
  end
end

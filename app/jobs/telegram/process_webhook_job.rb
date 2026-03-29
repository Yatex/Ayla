module Telegram
  class ProcessWebhookJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    def perform(payload)
      Telegram::WebhookProcessor.call(payload)
    end
  end
end

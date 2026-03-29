module Telegram
  class SendMessageJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    def perform(chat_id:, text:, reply_markup: nil)
      BotClient.new.send_message(
        chat_id: chat_id,
        text: text,
        reply_markup: reply_markup
      )
    end
  end
end

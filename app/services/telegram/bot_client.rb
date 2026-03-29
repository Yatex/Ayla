module Telegram
  class BotClient
    def initialize(token: nil)
      @token = token || Rails.application.config.telegram.bot_token
      @api = ::Telegram::Bot::Api.new(@token)
    end

    def send_message(chat_id:, text:, reply_markup: nil, parse_mode: "Markdown")
      params = {
        chat_id: chat_id,
        text: text,
        parse_mode: parse_mode
      }
      params[:reply_markup] = reply_markup if reply_markup
      @api.call("sendMessage", params)
    end

    def send_message_with_buttons(chat_id:, text:, buttons:)
      keyboard = ::Telegram::Bot::Types::InlineKeyboardMarkup.new(
        inline_keyboard: buttons
      )
      send_message(chat_id: chat_id, text: text, reply_markup: keyboard)
    end

    def answer_callback_query(callback_query_id:, text: nil)
      params = { callback_query_id: callback_query_id }
      params[:text] = text if text
      @api.call("answerCallbackQuery", params)
    end
  end
end

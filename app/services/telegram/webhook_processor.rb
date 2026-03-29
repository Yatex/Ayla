module Telegram
  class WebhookProcessor < ApplicationService
    def initialize(payload)
      @payload = payload.deep_symbolize_keys
    end

    def call
      if @payload[:callback_query]
        handle_callback_query
      elsif @payload.dig(:message, :text)
        handle_message
      else
        Rails.logger.info("[Telegram::WebhookProcessor] Unsupported payload type")
      end
    end

    private

    def handle_message
      telegram_user = @payload.dig(:message, :from)
      chat_id = @payload.dig(:message, :chat, :id)
      text = @payload.dig(:message, :text)
      message_id = @payload.dig(:message, :message_id)

      connection = find_or_register_connection(telegram_user, chat_id, text)
      return unless connection

      MessageHandler.call(
        connection: connection,
        text: text,
        telegram_message_id: message_id
      )
    end

    def handle_callback_query
      callback = @payload[:callback_query]
      telegram_user_id = callback.dig(:from, :id)
      data = callback[:data]
      callback_query_id = callback[:id]

      connection = TelegramConnection.find_by_telegram_user(telegram_user_id)
      return unless connection

      CallbackHandler.call(
        connection: connection,
        data: data,
        callback_query_id: callback_query_id
      )
    end

    def find_or_register_connection(telegram_user, chat_id, text)
      if (link_token = start_link_token(text))
        return handle_start_link(telegram_user, chat_id, link_token)
      end

      connection = TelegramConnection.find_by_telegram_user(telegram_user[:id])
      return connection if connection

      bot_client.send_message(
        chat_id: chat_id,
        text: "Hey! I don't recognize you yet. Open the Telegram connect link from the Ayla web app, then tap Start here to finish linking your account."
      )
      nil
    end

    def start_link_token(text)
      command, payload = text.to_s.split(/\s+/, 2)
      return if command != "/start"

      payload.to_s.strip.presence
    end

    def handle_start_link(telegram_user, chat_id, link_token)
      user = User.find_for_telegram_link_token(link_token)
      unless user
        bot_client.send_message(
          chat_id: chat_id,
          text: "That Telegram connect link is invalid or expired. Generate a new one from Ayla settings and try again."
        )
        return nil
      end

      Telegram::ConnectionLinker.call(user: user, telegram_user: telegram_user, chat_id: chat_id)
    rescue Telegram::ConnectionLinker::LinkError => e
      bot_client.send_message(chat_id: chat_id, text: e.message)
      nil
    end

    def bot_client
      @bot_client ||= BotClient.new
    end
  end
end

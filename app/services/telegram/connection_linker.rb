module Telegram
  class ConnectionLinker < ApplicationService
    class LinkError < StandardError; end

    def initialize(user:, telegram_user:, chat_id:)
      @user = user
      @telegram_user = telegram_user
      @chat_id = chat_id
    end

    def call
      ActiveRecord::Base.transaction do
        ensure_telegram_account_is_available!

        connection = @user.telegram_connection || @user.build_telegram_connection
        connection.update!(
          telegram_user_id: @telegram_user[:id],
          telegram_chat_id: @chat_id,
          username: @telegram_user[:username],
          first_name: @telegram_user[:first_name],
          last_name: @telegram_user[:last_name],
          active: true,
          connected_at: connection.connected_at || Time.current
        )
        @user.clear_telegram_link_token!
        connection
      end
    end

    private

    def ensure_telegram_account_is_available!
      existing_connection = TelegramConnection.find_by(telegram_user_id: @telegram_user[:id])
      return if existing_connection.nil? || existing_connection.user == @user

      raise LinkError, "That Telegram account is already linked to another Ayla account."
    end
  end
end

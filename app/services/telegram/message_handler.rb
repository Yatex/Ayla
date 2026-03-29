module Telegram
  class MessageHandler < ApplicationService
    COMMANDS = %w[/start /help /draft /status /cancel].freeze

    def initialize(connection:, text:, telegram_message_id: nil)
      @connection = connection
      @user = connection.user
      @text = text.strip
      @telegram_message_id = telegram_message_id
    end

    def call
      if command?
        handle_command
      else
        handle_context_message
      end
    end

    private

    def command?
      COMMANDS.any? { |cmd| @text.start_with?(cmd) }
    end

    def handle_command
      case @text.split.first
      when "/start"
        send_welcome
      when "/help"
        send_help
      when "/draft"
        generate_draft
      when "/status"
        send_status
      when "/cancel"
        cancel_current
      end
    end

    def handle_context_message
      conversation = find_or_create_conversation
      conversation.add_message!(
        role: "user",
        content: @text,
        telegram_message_id: @telegram_message_id
      )

      @connection.start_collecting! if @connection.may_start_collecting?

      message_count = conversation.messages.by_role("user").count

      if message_count >= 3 || @text.length > 200
        suggest_draft(conversation)
      else
        send_reply("Got it! Keep sharing or send /draft when you're ready for me to create a post.")
      end
    end

    def suggest_draft(conversation)
      buttons = [[
        ::Telegram::Bot::Types::InlineKeyboardButton.new(
          text: "✨ Generate Draft",
          callback_data: "generate_draft:#{conversation.id}"
        ),
        ::Telegram::Bot::Types::InlineKeyboardButton.new(
          text: "📝 Keep Adding",
          callback_data: "keep_adding:#{conversation.id}"
        )
      ]]

      bot_client.send_message_with_buttons(
        chat_id: @connection.telegram_chat_id,
        text: "I have enough context to create a draft. Want me to generate one?",
        buttons: buttons
      )
    end

    def generate_draft
      conversation = current_conversation
      unless conversation&.messages&.exists?
        send_reply("No context yet! Share some thoughts or updates first, then send /draft.")
        return
      end

      Drafts::GenerateDraftJob.perform_later(conversation.id)
      send_reply("Working on your draft... ✍️")
    end

    def send_welcome
      send_reply(
        "Welcome back! Share what's happening today and I'll help you turn it into social media content.\n\n" \
        "Commands:\n" \
        "/draft — Generate a draft from your context\n" \
        "/status — See your pending drafts\n" \
        "/help — Show help\n" \
        "/cancel — Cancel current conversation"
      )
    end

    def send_help
      send_reply(
        "*How to use Ayla:*\n\n" \
        "1. Share context — Tell me about your day, wins, thoughts, ideas\n" \
        "2. I'll suggest a draft — Or send /draft anytime\n" \
        "3. Review & approve — Tap approve or request changes\n" \
        "4. I'll post it — To your connected platforms\n\n" \
        "That's it! Just start typing."
      )
    end

    def send_status
      pending = @user.content_drafts.pending.count
      approved = @user.content_drafts.approved_drafts.count
      send_reply("📊 *Your drafts:*\nPending approval: #{pending}\nApproved: #{approved}")
    end

    def cancel_current
      conversation = current_conversation
      if conversation
        conversation.complete!
        @connection.reset! if @connection.may_reset?
        send_reply("Conversation cancelled. Send me new context whenever you're ready!")
      else
        send_reply("Nothing to cancel. Start sharing context anytime!")
      end
    end

    def current_conversation
      @connection.conversations.active.order(created_at: :desc).first
    end

    def find_or_create_conversation
      current_conversation || @connection.conversations.create!(
        user: @user,
        started_at: Time.current
      )
    end

    def send_reply(text)
      bot_client.send_message(
        chat_id: @connection.telegram_chat_id,
        text: text
      )
    end

    def bot_client
      @bot_client ||= BotClient.new
    end
  end
end

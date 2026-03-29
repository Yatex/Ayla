module Telegram
  class CallbackHandler < ApplicationService
    def initialize(connection:, data:, callback_query_id:)
      @connection = connection
      @user = connection.user
      @data = data
      @callback_query_id = callback_query_id
    end

    def call
      action, id = @data.split(":")

      case action
      when "generate_draft"
        handle_generate_draft(id.to_i)
      when "keep_adding"
        handle_keep_adding
      when "approve_draft"
        handle_approve_draft(id.to_i)
      when "reject_draft"
        handle_reject_draft(id.to_i)
      when "edit_draft"
        handle_edit_draft(id.to_i)
      else
        Rails.logger.warn("[Telegram::CallbackHandler] Unknown action: #{action}")
      end

      answer_callback
    end

    private

    def handle_generate_draft(conversation_id)
      conversation = @user.conversations.find(conversation_id)
      Drafts::GenerateDraftJob.perform_later(conversation.id)
      send_reply("Working on your draft... ✍️")
    end

    def handle_keep_adding
      send_reply("Sure! Keep sharing and send /draft when you're ready.")
    end

    def handle_approve_draft(draft_id)
      draft = @user.content_drafts.find(draft_id)
      Drafts::ApprovalHandler.call(draft: draft, action: :approve)
      send_reply("Draft approved! ✅ It's queued for posting.")
    end

    def handle_reject_draft(draft_id)
      draft = @user.content_drafts.find(draft_id)
      Drafts::ApprovalHandler.call(draft: draft, action: :reject)
      send_reply("Draft rejected. Send me more context or /draft to try again.")
    end

    def handle_edit_draft(draft_id)
      send_reply("Send me your edits and I'll update the draft. (Coming soon!)")
    end

    def send_reply(text)
      BotClient.new.send_message(
        chat_id: @connection.telegram_chat_id,
        text: text
      )
    end

    def answer_callback
      BotClient.new.answer_callback_query(callback_query_id: @callback_query_id)
    end
  end
end

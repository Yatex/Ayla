module Drafts
  class Generator < ApplicationService
    def initialize(conversation:)
      @conversation = conversation
      @user = conversation.user
    end

    def call
      context = Conversations::Manager.new(conversation: @conversation).build_context
      preferences = @user.user_preference
      profile = @user.user_profile
      active_campaign = @user.campaign_plans.chronological.to_a.find(&:active_now?) || @user.campaign_plans.find_by(status: "active")

      prompt = Ai::PromptBuilder.call(
        context: context,
        tone: preferences&.tone || "professional",
        custom_instructions: preferences&.custom_instructions,
        brand_context: profile&.strategy_context(preference: preferences),
        content_topics: preferences&.normalized_content_types || [],
        preferred_platforms: preferences&.normalized_preferred_platforms || [],
        posting_frequency: preferences&.posting_frequency,
        active_campaign: active_campaign&.message_angle.presence || active_campaign&.objective
      )

      response = Ai::Client.call(prompt: prompt)

      draft = @user.content_drafts.create!(
        conversation: @conversation,
        body: response,
        status: "pending_approval"
      )

      send_draft_for_approval(draft)
      draft
    end

    private

    def send_draft_for_approval(draft)
      connection = @user.telegram_connection
      return unless connection&.active?

      buttons = [[
        ::Telegram::Bot::Types::InlineKeyboardButton.new(
          text: "✅ Approve",
          callback_data: "approve_draft:#{draft.id}"
        ),
        ::Telegram::Bot::Types::InlineKeyboardButton.new(
          text: "❌ Reject",
          callback_data: "reject_draft:#{draft.id}"
        )
      ]]

      Telegram::BotClient.new.send_message_with_buttons(
        chat_id: connection.telegram_chat_id,
        text: "Here's your draft:\n\n#{draft.body}\n\n_Tap to approve or reject._",
        buttons: buttons
      )
    end
  end
end

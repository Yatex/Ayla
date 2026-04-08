module Ai
  class PromptBuilder < ApplicationService
    def initialize(context:, tone: "professional", custom_instructions: nil, brand_context: nil, content_topics: [], preferred_platforms: [], posting_frequency: nil, active_campaign: nil)
      @context = context
      @tone = tone
      @custom_instructions = custom_instructions
      @brand_context = brand_context
      @content_topics = Array(content_topics)
      @preferred_platforms = Array(preferred_platforms)
      @posting_frequency = posting_frequency
      @active_campaign = active_campaign
    end

    def call
      [system_message] + user_context_messages
    end

    private

    def system_message
      instructions = <<~PROMPT
        You are Ayla, an AI social media assistant. Your job is to take real context from a user's day — thoughts, updates, wins, observations — and turn them into a compelling social media post.

        Guidelines:
        - Tone: #{@tone}
        - Posting rhythm target: #{@posting_frequency.presence || "not specified"}
        - Write a single, ready-to-post draft
        - Keep it concise and engaging
        - Don't use hashtags unless they add real value
        - Sound human, not robotic
        - Match the user's voice based on their messages
      PROMPT

      instructions += "\n- Core topics to emphasize: #{@content_topics.join(', ')}" if @content_topics.any?
      instructions += "\n- Preferred publishing platforms: #{@preferred_platforms.join(', ')}" if @preferred_platforms.any?
      instructions += "\n- Brand and business context: #{@brand_context}" if @brand_context.present?
      instructions += "\n- Active campaign direction: #{@active_campaign}" if @active_campaign.present?
      instructions += "\n\nAdditional instructions: #{@custom_instructions}" if @custom_instructions.present?

      { role: "system", content: instructions.strip }
    end

    def user_context_messages
      @context.select { |m| m[:role] == "user" }.map do |m|
        { role: "user", content: m[:content] }
      end + [{ role: "user", content: "Based on all the context I've shared, write me a social media post." }]
    end
  end
end

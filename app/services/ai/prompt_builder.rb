module Ai
  class PromptBuilder < ApplicationService
    def initialize(context:, tone: "professional", custom_instructions: nil)
      @context = context
      @tone = tone
      @custom_instructions = custom_instructions
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
        - Write a single, ready-to-post draft
        - Keep it concise and engaging
        - Don't use hashtags unless they add real value
        - Sound human, not robotic
        - Match the user's voice based on their messages
      PROMPT

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

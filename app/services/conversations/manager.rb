module Conversations
  class Manager < ApplicationService
    def initialize(conversation:)
      @conversation = conversation
      @user = conversation.user
    end

    def call
      build_context
    end

    def build_context
      messages = @conversation.context_messages
      messages.map { |m| { role: m.role, content: m.content } }
    end

    def sufficient_context?
      user_messages = @conversation.messages.by_role("user")
      user_messages.count >= 2 || user_messages.sum { |m| m.content.length } > 150
    end
  end
end

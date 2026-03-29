module Drafts
  class GenerateDraftJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    def perform(conversation_id)
      conversation = Conversation.find(conversation_id)
      Drafts::Generator.call(conversation: conversation)
    end
  end
end

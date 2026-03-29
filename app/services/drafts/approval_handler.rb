module Drafts
  class ApprovalHandler < ApplicationService
    def initialize(draft:, action:, reason: nil)
      @draft = draft
      @action = action.to_sym
      @reason = reason
    end

    def call
      case @action
      when :approve
        @draft.approve!
        complete_conversation
      when :reject
        @draft.update!(rejection_reason: @reason) if @reason.present?
        @draft.reject!
        reset_connection_state
      end

      @draft
    end

    private

    def complete_conversation
      conversation = @draft.conversation
      conversation&.complete! if conversation&.may_complete?

      connection = @draft.user.telegram_connection
      connection&.reset! if connection&.may_reset?
    end

    def reset_connection_state
      connection = @draft.user.telegram_connection
      connection&.reset! if connection&.may_reset?
    end
  end
end

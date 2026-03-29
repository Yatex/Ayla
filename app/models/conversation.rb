class Conversation < ApplicationRecord
  include AASM

  belongs_to :user
  belongs_to :telegram_connection
  has_many :messages, dependent: :destroy
  has_many :content_drafts, dependent: :nullify

  aasm column: :status do
    state :active, initial: true
    state :completed

    event :complete do
      transitions from: :active, to: :completed
      after do
        update!(ended_at: Time.current)
      end
    end
  end

  scope :active, -> { where(status: "active") }
  scope :recent, -> { order(created_at: :desc) }

  def add_message!(role:, content:, telegram_message_id: nil, metadata: {})
    messages.create!(
      role: role,
      content: content,
      telegram_message_id: telegram_message_id,
      metadata: metadata
    )
  end

  def context_messages
    messages.order(:created_at)
  end
end

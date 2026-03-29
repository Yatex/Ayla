class TelegramConnection < ApplicationRecord
  include AASM

  belongs_to :user
  has_many :conversations, dependent: :destroy

  validates :telegram_user_id, presence: true, uniqueness: true
  validates :telegram_chat_id, presence: true

  aasm column: :state do
    state :idle, initial: true
    state :collecting_context
    state :awaiting_approval

    event :start_collecting do
      transitions from: :idle, to: :collecting_context
    end

    event :submit_for_approval do
      transitions from: :collecting_context, to: :awaiting_approval
    end

    event :reset do
      transitions from: [:collecting_context, :awaiting_approval], to: :idle
    end
  end

  scope :active, -> { where(active: true) }

  def self.find_by_telegram_user(telegram_user_id)
    find_by(telegram_user_id: telegram_user_id, active: true)
  end
end

class ContentDraft < ApplicationRecord
  include AASM

  belongs_to :user
  belongs_to :conversation, optional: true

  validates :body, presence: true

  aasm column: :status do
    state :draft, initial: true
    state :pending_approval
    state :approved
    state :rejected

    event :submit do
      transitions from: :draft, to: :pending_approval
    end

    event :approve do
      transitions from: :pending_approval, to: :approved
      after do
        update!(approved_at: Time.current)
      end
    end

    event :reject do
      transitions from: :pending_approval, to: :rejected
      after do
        update!(rejected_at: Time.current)
      end
    end
  end

  scope :recent, -> { order(created_at: :desc) }
  scope :pending, -> { where(status: "pending_approval") }
  scope :approved_drafts, -> { where(status: "approved") }
end

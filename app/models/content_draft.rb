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

  def metadata_hash
    metadata.is_a?(Hash) ? metadata.deep_stringify_keys : {}
  end

  def media_url
    metadata_hash["media_url"].presence
  end

  def media_url=(value)
    next_metadata = metadata_hash.except("media_url")
    next_metadata["media_url"] = value.to_s.strip if value.to_s.strip.present?
    self.metadata = next_metadata
  end

  def published_posts
    value = metadata_hash["published_posts"]
    value.is_a?(Hash) ? value.deep_stringify_keys : {}
  end

  def store_published_post(provider:, payload:)
    next_posts = published_posts.merge(provider.to_s => payload.deep_stringify_keys)
    self.metadata = metadata_hash.merge("published_posts" => next_posts)
  end
end

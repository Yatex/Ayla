class Message < ApplicationRecord
  belongs_to :conversation

  ROLES = %w[user assistant system].freeze

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :content, presence: true

  scope :chronological, -> { order(:created_at) }
  scope :by_role, ->(role) { where(role: role) }
end

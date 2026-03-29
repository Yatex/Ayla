class UserPreference < ApplicationRecord
  belongs_to :user

  TONES = %w[professional casual friendly witty inspirational informative].freeze
  FREQUENCIES = %w[daily every_other_day weekly custom].freeze

  validates :tone, inclusion: { in: TONES }
  validates :posting_frequency, inclusion: { in: FREQUENCIES }
end

class UserPreference < ApplicationRecord
  PLATFORMS = %w[instagram linkedin x].freeze
  ASSISTANT_CHANNELS = %w[telegram whatsapp].freeze
  belongs_to :user

  TONES = %w[professional casual friendly witty inspirational informative].freeze
  FREQUENCIES = %w[daily every_other_day weekly custom].freeze

  validates :tone, inclusion: { in: TONES }
  validates :posting_frequency, inclusion: { in: FREQUENCIES }
  validates :assistant_channel, inclusion: { in: ASSISTANT_CHANNELS }

  def normalized_preferred_platforms
    sanitize_list(preferred_platforms, allowed: PLATFORMS, downcase: true)
  end

  def normalized_content_types
    sanitize_list(content_types)
  end

  private

  def sanitize_list(values, allowed: nil, downcase: false)
    items = Array(values).filter_map { |value| value.to_s.strip.presence }
    items = items.map(&:downcase) if downcase
    items = items.uniq
    allowed.present? ? items & allowed : items
  end
end

class UserProfile < ApplicationRecord
  belongs_to :user

  ONBOARDING_STEPS = %w[pending profile_info preferences telegram_connect completed].freeze

  validates :timezone, presence: true
  validates :language, presence: true
  validates :onboarding_step, inclusion: { in: ONBOARDING_STEPS }

  def strategy_completion(preference: nil)
    items = strategy_completion_items(preference: preference)
    completed = items.count { |item| item[:present] }

    {
      completed: completed,
      total: items.size,
      percent: ((completed.to_f / items.size) * 100).round
    }
  end

  def strategy_completion_items(preference: nil)
    [
      { key: :brand_summary, label: "Brand summary", present: brand_summary.present? || bio.present? },
      { key: :positioning, label: "Positioning", present: positioning.present? },
      { key: :target_audience, label: "Audience", present: target_audience.present? },
      { key: :strategic_objectives, label: "Objectives", present: strategic_objectives.present? },
      { key: :main_offers, label: "Offers", present: main_offers.present? },
      { key: :content_pillars, label: "Content pillars", present: preference&.normalized_content_types&.any? },
      { key: :tone, label: "Tone", present: preference&.tone.present? },
      { key: :strategic_notes, label: "Strategic notes", present: strategic_notes.present? || preference&.custom_instructions.present? }
    ]
  end

  def strategy_context(preference: nil)
    parts = []
    parts << "Brand summary: #{brand_summary.presence || bio}" if brand_summary.present? || bio.present?
    parts << "Positioning: #{positioning}" if positioning.present?
    parts << "Audience: #{target_audience}" if target_audience.present?
    parts << "Objectives: #{strategic_objectives}" if strategic_objectives.present?
    parts << "Offers and expertise: #{main_offers}" if main_offers.present?
    parts << "Content pillars: #{preference.normalized_content_types.join(', ')}" if preference&.normalized_content_types&.any?
    parts << "Tone and voice: #{preference.tone}" if preference&.tone.present?
    parts << "Strategic notes: #{strategic_notes}" if strategic_notes.present?
    parts << "Operating instructions: #{preference.custom_instructions}" if preference&.custom_instructions.present?
    parts.join("\n")
  end

  def complete_onboarding!
    update!(onboarding_step: "completed", onboarded_at: Time.current)
  end

  def onboarding_complete?
    onboarding_step == "completed"
  end
end

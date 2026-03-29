class UserProfile < ApplicationRecord
  belongs_to :user

  ONBOARDING_STEPS = %w[pending profile_info preferences telegram_connect completed].freeze

  validates :timezone, presence: true
  validates :language, presence: true
  validates :onboarding_step, inclusion: { in: ONBOARDING_STEPS }

  def complete_onboarding!
    update!(onboarding_step: "completed", onboarded_at: Time.current)
  end

  def onboarding_complete?
    onboarding_step == "completed"
  end
end

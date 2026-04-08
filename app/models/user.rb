class User < ApplicationRecord
  TELEGRAM_LINK_TOKEN_TTL = 15.minutes

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :user_profile, dependent: :destroy
  has_one :user_preference, dependent: :destroy
  has_one :telegram_connection, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :content_drafts, dependent: :destroy
  has_many :social_accounts, dependent: :destroy
  has_many :campaign_plans, dependent: :destroy

  validates :name, presence: true

  after_create :create_defaults

  def onboarded?
    user_profile&.onboarded_at.present?
  end

  def telegram_connected?
    telegram_connection&.active?
  end

  def social_account_for(provider)
    social_accounts.find_by(provider: provider)
  end

  def ensure_telegram_link_token!
    return telegram_link_token if telegram_link_token_active?

    update!(
      telegram_link_token: generate_telegram_link_token,
      telegram_link_token_generated_at: Time.current
    )

    telegram_link_token
  end

  def clear_telegram_link_token!
    update!(telegram_link_token: nil, telegram_link_token_generated_at: nil)
  end

  def telegram_link_token_active?
    telegram_link_token.present? &&
      telegram_link_token_generated_at.present? &&
      telegram_link_token_generated_at >= TELEGRAM_LINK_TOKEN_TTL.ago
  end

  def self.find_for_telegram_link_token(token)
    return if token.blank?

    where(telegram_link_token: token)
      .where("telegram_link_token_generated_at >= ?", TELEGRAM_LINK_TOKEN_TTL.ago)
      .first
  end

  private

  def create_defaults
    create_user_profile! unless user_profile
    create_user_preference! unless user_preference
  end

  def generate_telegram_link_token
    loop do
      token = SecureRandom.urlsafe_base64(18)
      break token unless self.class.exists?(telegram_link_token: token)
    end
  end
end

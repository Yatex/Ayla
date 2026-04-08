class SocialAccount < ApplicationRecord
  belongs_to :user

  encrypts :access_token, :refresh_token

  validates :provider, inclusion: { in: UserPreference::PLATFORMS }
  validates :external_uid, presence: true

  scope :connected, -> { where(active: true) }

  def connected?
    active? && access_token.present?
  end

  def expired?
    expires_at.present? && expires_at <= 5.minutes.from_now
  end

  def metadata_hash
    metadata.is_a?(Hash) ? metadata.deep_stringify_keys : {}
  end

  def display_handle
    username.presence || metadata_hash["name"].presence || external_uid
  end
end

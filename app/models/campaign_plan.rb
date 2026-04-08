class CampaignPlan < ApplicationRecord
  STATUSES = %w[draft active completed archived].freeze

  belongs_to :user

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :start_on, presence: true
  validates :end_on, presence: true
  validate :end_on_after_start_on

  scope :chronological, -> { order(start_on: :asc, end_on: :asc, created_at: :asc) }
  scope :active_status, -> { where(status: "active") }
  scope :upcoming, -> { where("start_on > ?", Date.current).chronological }
  scope :completed_or_archived, -> { where(status: %w[completed archived]).order(end_on: :desc, created_at: :desc) }

  def focus_areas_list
    Array(focus_areas).filter_map { |value| value.to_s.strip.presence }
  end

  def focus_areas_text
    focus_areas_list.join("\n")
  end

  def current_window?
    start_on.present? && end_on.present? && start_on <= Date.current && end_on >= Date.current
  end

  def active_now?
    status == "active" && current_window?
  end

  def timeline_label
    return "" if start_on.blank? || end_on.blank?

    if start_on.month == end_on.month && start_on.year == end_on.year
      "#{start_on.strftime('%b %-d')} - #{end_on.strftime('%-d, %Y')}"
    else
      "#{start_on.strftime('%b %-d, %Y')} - #{end_on.strftime('%b %-d, %Y')}"
    end
  end

  def duration_in_months
    return 0 if start_on.blank? || end_on.blank?

    ((end_on.year * 12 + end_on.month) - (start_on.year * 12 + start_on.month) + 1).clamp(1, 24)
  end

  private

  def end_on_after_start_on
    return if start_on.blank? || end_on.blank?
    return if end_on >= start_on

    errors.add(:end_on, "must be on or after the start date")
  end
end

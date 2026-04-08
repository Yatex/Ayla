class WorkspaceSnapshot < ApplicationService
  Task = Struct.new(:kind, :title, :detail, :due_label, :tone, keyword_init: true)
  RhythmPoint = Struct.new(:label, :date, :count, keyword_init: true)
  CalendarDay = Struct.new(:label, :date, :drafts, keyword_init: true)

  def initialize(user:)
    @user = user
  end

  def call
    self
  end

  def status
    if preferred_platforms.blank?
      {
        label: "Channels still need setup",
        detail: "Choose Instagram, LinkedIn, or X so Ayla knows where this content system is meant to publish.",
        tone: "warning"
      }
    elsif assistant_channel == "whatsapp"
      {
        label: "WhatsApp selected",
        detail: "WhatsApp is set as the preferred assistant channel. Direct connection is the next integration step.",
        tone: "warning"
      }
    elsif !user.telegram_connected?
      {
        label: "Assistant not linked",
        detail: "Link Telegram so Ayla can catch real moments while they are fresh.",
        tone: "warning"
      }
    elsif pending_count.positive?
      {
        label: "Approval queue active",
        detail: "#{pending_count} #{'draft'.pluralize(pending_count)} waiting for review.",
        tone: "accent"
      }
    elsif drafts_this_week.positive?
      {
        label: "Rhythm active",
        detail: "#{drafts_this_week} #{'draft'.pluralize(drafts_this_week)} created in the last 7 days.",
        tone: "success"
      }
    else
      {
        label: "Quiet week",
        detail: "No fresh captures recently. Prompt Ayla for your next moment.",
        tone: "muted"
      }
    end
  end

  def pending_count
    pending_scope.count
  end

  def approved_count
    approved_scope.count
  end

  def rejected_count
    rejected_scope.count
  end

  def drafts_this_week
    scoped_drafts.where(created_at: 7.days.ago..Time.current).count
  end

  def total_count
    scoped_drafts.count
  end

  def approval_rate
    reviewed_count = approved_count + rejected_count
    return 0 if reviewed_count.zero?

    ((approved_count.to_f / reviewed_count) * 100).round
  end

  def approval_queue
    pending_scope.reorder(created_at: :asc).limit(4)
  end

  def recent_activity
    scoped_drafts.limit(6)
  end

  def last_activity_at
    @last_activity_at ||= scoped_drafts.maximum(:created_at)
  end

  def upcoming_tasks
    tasks = []

    unless user.telegram_connected?
      tasks << Task.new(
        kind: :link_telegram,
        title: "Link Telegram",
        detail: "Turn on the assistant so Ayla can prompt you in the moment.",
        due_label: "Now",
        tone: "accent"
      )
    end

    unless user.onboarded?
      tasks << Task.new(
        kind: :finish_onboarding,
        title: "Finish onboarding",
        detail: "Set your profile and preferences so Ayla can prompt with the right context.",
        due_label: "Today",
        tone: "muted"
      )
    end

    if pending_count.positive?
      tasks << Task.new(
        kind: :review_queue,
        title: "Clear approval queue",
        detail: "#{pending_count} #{'draft'.pluralize(pending_count)} waiting for a decision.",
        due_label: "Today",
        tone: "warning"
      )
    else
      tasks << Task.new(
        kind: :capture_new_moment,
        title: "Capture a new moment",
        detail: "No drafts are waiting right now. Feed Ayla a fresh clip, photo, or lesson.",
        due_label: "This week",
        tone: "muted"
      )
    end

    if last_activity_at.nil? || last_activity_at < 2.days.ago
      tasks << Task.new(
        kind: :restart_rhythm,
        title: "Restart the rhythm",
        detail: "Share one new update before this week gets buried under execution.",
        due_label: "Tomorrow",
        tone: "accent"
      )
    else
      tasks << Task.new(
        kind: :maintain_rhythm,
        title: "Keep the rhythm warm",
        detail: "You have recent activity. Capture one more meaningful moment before the week closes.",
        due_label: "Later this week",
        tone: "success"
      )
    end

    tasks.first(4)
  end

  def posting_rhythm(days: 7)
    start_date = days.days.ago.to_date
    counts = scoped_drafts
      .reorder(nil)
      .where(created_at: start_date.beginning_of_day..Time.current)
      .group(Arel.sql("DATE(created_at)"))
      .count

    (0...days).map do |offset|
      date = start_date + offset
      count = counts[date] || counts[date.to_s] || 0

      RhythmPoint.new(label: date.strftime("%a"), date: date, count: count)
    end
  end

  def calendar_week(week_offset: 0, platform: nil)
    start_date = calendar_week_start(week_offset: week_offset)
    finish_date = start_date + 6.days
    drafts = calendar_scope(platform: platform)
      .where(created_at: start_date.beginning_of_day..finish_date.end_of_day)
      .order(created_at: :asc)
      .to_a
      .group_by { |draft| draft.created_at.in_time_zone.to_date }

    (0..6).map do |offset|
      date = start_date + offset

      CalendarDay.new(
        label: date.strftime("%a"),
        date: date,
        drafts: drafts.fetch(date, [])
      )
    end
  end

  def calendar_week_label(week_offset: 0)
    start_date = calendar_week_start(week_offset: week_offset)
    finish_date = start_date + 6.days

    if start_date.month == finish_date.month
      "#{start_date.strftime('%b %-d')} - #{finish_date.strftime('%-d')}"
    else
      "#{start_date.strftime('%b %-d')} - #{finish_date.strftime('%b %-d')}"
    end
  end

  def status_breakdown
    [
      { label: "Draft", count: scoped_drafts.where(status: "draft").count, tone: "draft" },
      { label: "Pending", count: pending_count, tone: "pending" },
      { label: "Approved", count: approved_count, tone: "approved" },
      { label: "Rejected", count: rejected_count, tone: "rejected" }
    ]
  end

  private

  attr_reader :user

  def preferred_platforms
    user.user_preference&.normalized_preferred_platforms || []
  end

  def assistant_channel
    user.user_preference&.assistant_channel || "telegram"
  end

  def scoped_drafts
    @scoped_drafts ||= user.content_drafts.recent
  end

  def pending_scope
    @pending_scope ||= user.content_drafts.pending.recent
  end

  def approved_scope
    @approved_scope ||= user.content_drafts.approved_drafts
  end

  def rejected_scope
    @rejected_scope ||= user.content_drafts.where(status: "rejected")
  end

  def calendar_scope(platform: nil)
    scope = user.content_drafts
    return scope if platform.blank?

    scope.where("LOWER(platform) = ?", platform.downcase)
  end

  def calendar_week_start(week_offset:)
    Time.zone.today.beginning_of_week(:monday) + week_offset.weeks
  end
end

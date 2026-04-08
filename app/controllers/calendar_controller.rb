class CalendarController < ApplicationController
  before_action :authenticate_user!

  def show
    @workspace_snapshot = WorkspaceSnapshot.call(user: current_user)
    @campaign_plans = current_user.campaign_plans.chronological
    @active_plan = @campaign_plans.find(&:active_now?) || @campaign_plans.find { |plan| plan.status == "active" }
    @next_plan = @campaign_plans.find { |plan| plan.start_on.present? && plan.start_on > Date.current }
    @preferred_platforms = current_user.user_preference.normalized_preferred_platforms
    @available_platform_filters = ["all"] + UserPreference::PLATFORMS
    @selected_platform = sanitized_platform_filter
    @week_offset = params[:week_offset].to_i.clamp(-26, 26)
    @calendar_days = @workspace_snapshot.calendar_week(
      week_offset: @week_offset,
      platform: (@selected_platform == "all" ? nil : @selected_platform)
    )
    @week_range_label = @workspace_snapshot.calendar_week_label(week_offset: @week_offset)
    @week_post_count = @calendar_days.sum { |day| day.drafts.count }
    @week_pending_count = @calendar_days.sum { |day| day.drafts.count(&:pending_approval?) }
    @week_approved_count = @calendar_days.sum { |day| day.drafts.count(&:approved?) }
  end

  private

  def sanitized_platform_filter
    selected = params[:platform].to_s.downcase
    @available_platform_filters.include?(selected) ? selected : "all"
  end
end

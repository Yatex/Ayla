class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :load_workspace_snapshot

  def show
    @profile = current_user.user_profile
    @preference = current_user.user_preference
    @telegram_connected = current_user.telegram_connected?
    @telegram_connect_url = telegram_connect_url_for(current_user)
    @telegram_bot_username = telegram_bot_username
    @preferred_platforms = @preference.normalized_preferred_platforms
    @assistant_channel = @preference.assistant_channel
    @platform_options = UserPreference::PLATFORMS
    @platforms_configured = @preferred_platforms.any?
    @strategy_completion = @profile.strategy_completion(preference: @preference)
    @strategy_gaps = @profile.strategy_completion_items(preference: @preference).reject { |item| item[:present] }
    @active_plan = active_plan
    @next_plan = next_plan
    @campaign_plans = current_user.campaign_plans.chronological
    @upcoming_content = upcoming_content
    @consistency_days = @posting_rhythm.count { |point| point.count.positive? }
    @setup_blockers = build_setup_blockers
  end

  private

  def load_workspace_snapshot
    @workspace_snapshot = WorkspaceSnapshot.call(user: current_user)
    @workspace_status = @workspace_snapshot.status
    @pending_count = @workspace_snapshot.pending_count
    @approved_count = @workspace_snapshot.approved_count
    @drafts_this_week = @workspace_snapshot.drafts_this_week
    @approval_rate = @workspace_snapshot.approval_rate
    @approval_queue = @workspace_snapshot.approval_queue
    @recent_activity = @workspace_snapshot.recent_activity
    @posting_rhythm = @workspace_snapshot.posting_rhythm
  end

  def active_plan
    @active_plan ||= begin
      plans = current_user.campaign_plans.chronological.to_a
      plans.find(&:active_now?) || plans.find { |plan| plan.status == "active" }
    end
  end

  def next_plan
    @next_plan ||= current_user.campaign_plans.upcoming.first
  end

  def upcoming_content
    days = @workspace_snapshot.calendar_week(week_offset: 0)
    items = days
      .select { |day| day.date >= Time.zone.today }
      .flat_map(&:drafts)

    items.first(5)
  end

  def build_setup_blockers
    blockers = []
    blockers << { label: "Strategy still needs definition", detail: "#{@strategy_gaps.size} strategic fields are still blank.", path: strategy_path } if @strategy_gaps.any?
    blockers << { label: "No active campaign", detail: "There is no live plan guiding the calendar right now.", path: planification_path } if @active_plan.blank?
    blockers << { label: "Publishing channels need setup", detail: "Choose and connect the social accounts Ayla should manage.", path: settings_path(anchor: "platforms") } if @preferred_platforms.blank?
    blockers << { label: "Assistant still needs linking", detail: "Connect Telegram or define the WhatsApp contact flow so Ayla can capture moments in real time.", path: settings_path(anchor: "assistant-channel") } if @assistant_channel == "telegram" && !@telegram_connected
    blockers
  end
end

class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :load_workspace_snapshot

  def show
    @telegram_connected = current_user.telegram_connected?
    @telegram_connect_url = telegram_connect_url_for(current_user)
    @telegram_bot_username = telegram_bot_username
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
    @upcoming_tasks = @workspace_snapshot.upcoming_tasks
    @posting_rhythm = @workspace_snapshot.posting_rhythm
  end
end

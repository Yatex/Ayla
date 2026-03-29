class InsightsController < ApplicationController
  before_action :authenticate_user!

  def show
    @workspace_snapshot = WorkspaceSnapshot.call(user: current_user)
    @status_breakdown = @workspace_snapshot.status_breakdown
    @posting_rhythm = @workspace_snapshot.posting_rhythm
    @pending_count = @workspace_snapshot.pending_count
    @approved_count = @workspace_snapshot.approved_count
    @drafts_this_week = @workspace_snapshot.drafts_this_week
    @approval_rate = @workspace_snapshot.approval_rate
    @last_activity_at = @workspace_snapshot.last_activity_at
  end
end

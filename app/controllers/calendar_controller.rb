class CalendarController < ApplicationController
  before_action :authenticate_user!

  def show
    @workspace_snapshot = WorkspaceSnapshot.call(user: current_user)
    @upcoming_tasks = @workspace_snapshot.upcoming_tasks
    @posting_rhythm = @workspace_snapshot.posting_rhythm
    @approval_queue = @workspace_snapshot.approval_queue
    @telegram_connect_url = telegram_connect_url_for(current_user)
    @telegram_bot_username = telegram_bot_username
  end
end

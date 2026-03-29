class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @recent_drafts = current_user.content_drafts.recent.limit(5)
    @pending_count = current_user.content_drafts.pending.count
    @approved_count = current_user.content_drafts.approved_drafts.count
    @telegram_connected = current_user.telegram_connected?
    @telegram_connect_url = telegram_connect_url_for(current_user)
    @telegram_bot_username = telegram_bot_username
  end
end

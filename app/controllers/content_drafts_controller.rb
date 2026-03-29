class ContentDraftsController < ApplicationController
  before_action :authenticate_user!

  def index
    @drafts = current_user.content_drafts.recent.limit(50)
  end

  def show
    @draft = current_user.content_drafts.find(params[:id])
  end
end

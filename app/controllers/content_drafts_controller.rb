class ContentDraftsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_draft, only: [:show, :update, :publish]

  def index
    redirect_to calendar_path
  end

  def show
    @social_accounts = current_user.social_accounts.connected.order(:provider)
  end

  def update
    @draft.media_url = draft_params[:media_url]
    @draft.save!

    redirect_to content_draft_path(@draft), notice: "Draft details updated."
  end

  def publish
    providers = sanitized_publish_providers
    result = Social::Publisher.call(draft: @draft, user: current_user, providers: providers)

    redirect_to content_draft_path(@draft),
      (result.failures.any? && result.successes.none? ? { alert: result.summary } : { notice: result.summary })
  rescue Social::Error => e
    redirect_to content_draft_path(@draft), alert: e.message
  end

  private

  def load_draft
    @draft = current_user.content_drafts.find(params[:id])
  end

  def draft_params
    params.fetch(:content_draft, {}).permit(:media_url)
  end

  def sanitized_publish_providers
    Array(params[:providers]).filter_map { |value| value.to_s.strip.downcase.presence }.uniq & UserPreference::PLATFORMS
  end
end

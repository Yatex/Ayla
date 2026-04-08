class StrategyController < ApplicationController
  before_action :authenticate_user!

  def show
    @profile = current_user.user_profile
    @preference = current_user.user_preference
    @topics_text = @preference.normalized_content_types.join("\n")
    @strategy_completion = @profile.strategy_completion(preference: @preference)
  end

  def update
    profile = current_user.user_profile
    preference = current_user.user_preference

    profile.update!(profile_params) if params[:user_profile]
    preference.update!(preference_params) if params[:user_preference]

    redirect_to strategy_path, notice: "Strategy updated."
  end

  private

  def profile_params
    params.require(:user_profile).permit(
      :brand_summary,
      :positioning,
      :target_audience,
      :strategic_objectives,
      :main_offers,
      :bio,
      :strategic_notes
    )
  end

  def preference_params
    attributes = params.require(:user_preference).permit(:tone, :posting_frequency, :custom_instructions)
    attributes[:content_types] = sanitize_topics(params.dig(:user_preference, :content_topics))
    attributes
  end

  def sanitize_topics(raw_value)
    raw_value.to_s
      .split(/[\n,]/)
      .filter_map { |value| value.to_s.strip.presence }
      .uniq
      .first(12)
  end
end

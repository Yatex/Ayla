class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @profile = current_user.user_profile
    @preference = current_user.user_preference
    @preferred_platforms = @preference.normalized_preferred_platforms
    @assistant_channel = @preference.assistant_channel
    @whatsapp_number = @preference.whatsapp_number.to_s
    @telegram = current_user.telegram_connection
    @social_accounts_by_provider = current_user.social_accounts.index_by(&:provider)
    @telegram_connect_url = telegram_connect_url_for(current_user)
    @telegram_bot_username = telegram_bot_username
  end

  def update
    @profile = current_user.user_profile
    @preference = current_user.user_preference

    @profile.update!(profile_params) if params[:user_profile]
    @preference.update!(preference_params) if params[:user_preference]

    redirect_to redirect_target, notice: "Configuration updated."
  end

  private

  def profile_params
    params.require(:user_profile).permit(:timezone, :language)
  end

  def preference_params
    attributes = params.require(:user_preference).permit(:assistant_channel, :whatsapp_number, preferred_platforms: [])
    attributes[:preferred_platforms] = sanitize_platforms(attributes[:preferred_platforms]) if attributes.key?(:preferred_platforms)
    attributes[:assistant_channel] = sanitize_assistant_channel(attributes[:assistant_channel]) if attributes.key?(:assistant_channel)
    attributes[:whatsapp_number] = attributes[:whatsapp_number].to_s.strip.presence if attributes.key?(:whatsapp_number)
    attributes
  end

  def sanitize_platforms(values)
    Array(values).filter_map { |value| value.to_s.strip.downcase.presence }.uniq & UserPreference::PLATFORMS
  end

  def sanitize_assistant_channel(value)
    selected = value.to_s.strip.downcase
    UserPreference::ASSISTANT_CHANNELS.include?(selected) ? selected : "telegram"
  end

  def redirect_target
    requested_path = params[:return_to].presence
    allowed_paths = [dashboard_path, settings_path]

    allowed_paths.include?(requested_path) ? requested_path : settings_path
  end
end

class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @profile = current_user.user_profile
    @preference = current_user.user_preference
    @telegram = current_user.telegram_connection
    @telegram_connect_url = telegram_connect_url_for(current_user)
    @telegram_bot_username = telegram_bot_username
  end

  def update
    @profile = current_user.user_profile
    @preference = current_user.user_preference

    @profile.update!(profile_params) if params[:user_profile]
    @preference.update!(preference_params) if params[:user_preference]

    redirect_to settings_path, notice: "Settings updated."
  end

  private

  def profile_params
    params.require(:user_profile).permit(:bio, :timezone, :language)
  end

  def preference_params
    params.require(:user_preference).permit(:tone, :posting_frequency, :custom_instructions)
  end
end

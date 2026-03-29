class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_onboarded

  def show
    @profile = current_user.user_profile
    @step = @profile.onboarding_step
    @telegram_connect_url = telegram_connect_url_for(current_user)
    @telegram_bot_username = telegram_bot_username
  end

  def update
    @profile = current_user.user_profile
    preference = current_user.user_preference

    case params[:step]
    when "profile_info"
      @profile.update!(profile_params)
      @profile.update!(onboarding_step: "preferences")
    when "preferences"
      preference.update!(preference_params)
      @profile.update!(onboarding_step: "telegram_connect")
    when "telegram_connect"
      @profile.complete_onboarding!
      redirect_to overview_path, notice: "You're all set!" and return
    end

    redirect_to onboarding_path
  end

  private

  def redirect_if_onboarded
    redirect_to overview_path if current_user.onboarded?
  end

  def profile_params
    params.require(:user_profile).permit(:bio, :timezone, :language)
  end

  def preference_params
    params.require(:user_preference).permit(:tone, :posting_frequency, :custom_instructions)
  end
end

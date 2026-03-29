class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  helper_method :telegram_bot_username, :telegram_connect_url_for

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def after_sign_in_path_for(resource)
    if resource.onboarded?
      overview_path
    else
      onboarding_path
    end
  end

  def telegram_connect_url_for(user)
    return if user.telegram_connected?
    return if telegram_bot_username.blank?

    token = user.ensure_telegram_link_token!
    "https://t.me/#{telegram_bot_username}?start=#{ERB::Util.url_encode(token)}"
  end

  def telegram_bot_username
    Rails.application.config.telegram.bot_username
  end
end

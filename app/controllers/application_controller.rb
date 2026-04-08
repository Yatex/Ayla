class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  around_action :use_user_timezone, if: :ayla_signed_in?
  helper_method :telegram_bot_username, :telegram_connect_url_for, :ayla_signed_in?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def after_sign_in_path_for(resource)
    if resource.onboarded?
      dashboard_path
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

  def ayla_signed_in?
    user_signed_in?
  rescue Devise::MissingWarden
    false
  end

  def use_user_timezone(&block)
    timezone = current_user&.user_profile&.timezone
    return yield if timezone.blank?

    Time.use_zone(timezone, &block)
  end
end

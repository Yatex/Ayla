class SocialAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_provider_client

  def connect
    unless @provider_client.configured?
      redirect_to settings_path(anchor: "platforms"), alert: "#{platform_display_name(provider)} is not configured yet." and return
    end

    session[oauth_session_key] = {
      "state" => SecureRandom.hex(24),
      "code_verifier" => (@provider_client.requires_pkce? ? @provider_client.generate_code_verifier : nil)
    }

    redirect_to @provider_client.authorization_url(
      redirect_uri: callback_uri,
      state: session[oauth_session_key]["state"],
      code_verifier: session[oauth_session_key]["code_verifier"]
    ), allow_other_host: true
  end

  def callback
    if params[:error].present?
      redirect_to settings_path(anchor: "platforms"), alert: "#{platform_display_name(provider)} authorization failed: #{params[:error_description].presence || params[:error]}" and return
    end

    oauth_session = session.delete(oauth_session_key)
    if oauth_session.blank? || oauth_session["state"] != params[:state].to_s
      redirect_to settings_path(anchor: "platforms"), alert: "#{platform_display_name(provider)} authentication could not be verified." and return
    end

    account_attributes = @provider_client.connect_account_attributes(
      code: params[:code].to_s,
      redirect_uri: callback_uri,
      code_verifier: oauth_session["code_verifier"]
    )

    account = current_user.social_accounts.find_or_initialize_by(provider: provider)
    account.assign_attributes(account_attributes)
    account.save!
    enable_provider_for_workspace!

    redirect_to settings_path(anchor: "platforms"), notice: "#{platform_display_name(provider)} connected."
  rescue Social::Error => e
    redirect_to settings_path(anchor: "platforms"), alert: e.message
  end

  def destroy
    current_user.social_accounts.find_by!(provider: provider).destroy!
    redirect_to settings_path(anchor: "platforms"), notice: "#{platform_display_name(provider)} disconnected."
  end

  private

  def load_provider_client
    @provider_client = Social::ProviderRegistry.fetch(provider)
  rescue ArgumentError
    redirect_to settings_path(anchor: "platforms"), alert: "That social provider is not supported." and return
  end

  def provider
    params[:provider].to_s.downcase
  end

  def oauth_session_key
    :"social_oauth_#{provider}"
  end

  def callback_uri
    "#{app_base_url}#{social_account_callback_path(provider: provider)}"
  end

  def app_base_url
    ENV["APP_URL"].presence || request.base_url
  end

  def enable_provider_for_workspace!
    preference = current_user.user_preference
    enabled_platforms = (preference.normalized_preferred_platforms + [provider]).uniq
    preference.update!(preferred_platforms: enabled_platforms)
  end
end

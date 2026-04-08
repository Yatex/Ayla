module Social
  module Providers
    class InstagramClient < BaseClient
      AUTH_URL = "https://www.instagram.com/oauth/authorize".freeze
      TOKEN_URL = "https://api.instagram.com/oauth/access_token".freeze
      LONG_LIVED_TOKEN_URL = "https://graph.instagram.com/access_token".freeze
      REFRESH_TOKEN_URL = "https://graph.instagram.com/refresh_access_token".freeze
      ME_URL = "https://graph.instagram.com/v24.0/me".freeze

      def supports_text_only_posts?
        false
      end

      def authorization_url(redirect_uri:, state:, code_verifier: nil)
        auth_query(
          AUTH_URL,
          client_id: client_id,
          redirect_uri: redirect_uri,
          response_type: "code",
          scope: scopes.join(","),
          state: state
        )
      end

      def connect_account_attributes(code:, redirect_uri:, code_verifier: nil)
        short_lived_token = post_form(
          TOKEN_URL,
          body: {
            client_id: client_id,
            client_secret: client_secret,
            grant_type: "authorization_code",
            redirect_uri: redirect_uri,
            code: code
          }
        )

        token_data = get_json(
          LONG_LIVED_TOKEN_URL,
          params: {
            grant_type: "ig_exchange_token",
            client_secret: client_secret,
            access_token: short_lived_token.fetch("access_token")
          }
        )

        profile = get_json(
          ME_URL,
          params: { fields: "id,username,name,profile_picture_url", access_token: token_data.fetch("access_token") }
        )

        {
          external_uid: profile.fetch("id"),
          username: profile["username"],
          access_token: token_data.fetch("access_token"),
          refresh_token: nil,
          expires_at: expires_at_from(token_data["expires_in"]),
          active: true,
          connected_at: Time.current,
          last_synced_at: Time.current,
          metadata: {
            "name" => profile["name"],
            "profile_picture_url" => profile["profile_picture_url"]
          }
        }
      end

      def publish!(account:, draft:)
        raise Social::Error, "Instagram publishing needs a public media URL on the draft." if draft.media_url.blank?

        refresh_account!(account) if account.expired?

        container = post_form(
          "https://graph.instagram.com/v24.0/#{account.external_uid}/media",
          body: {
            image_url: draft.media_url,
            caption: draft.body,
            access_token: account.access_token
          }
        )

        response = post_form(
          "https://graph.instagram.com/v24.0/#{account.external_uid}/media_publish",
          body: {
            creation_id: container.fetch("id"),
            access_token: account.access_token
          }
        )

        { remote_id: response.fetch("id"), url: nil }
      end

      private

      def refresh_account!(account)
        token_data = get_json(
          REFRESH_TOKEN_URL,
          params: {
            grant_type: "ig_refresh_token",
            access_token: account.access_token
          }
        )

        account.update!(
          access_token: token_data.fetch("access_token"),
          expires_at: expires_at_from(token_data["expires_in"]),
          last_synced_at: Time.current
        )
      end

      def scopes
        %w[instagram_business_basic instagram_business_content_publish]
      end

      def client_id
        ENV["INSTAGRAM_CLIENT_ID"]
      end

      def client_secret
        ENV["INSTAGRAM_CLIENT_SECRET"]
      end
    end
  end
end

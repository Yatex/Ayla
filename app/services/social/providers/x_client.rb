module Social
  module Providers
    class XClient < BaseClient
      AUTH_URL = "https://x.com/i/oauth2/authorize".freeze
      TOKEN_URL = "https://api.x.com/2/oauth2/token".freeze
      ME_URL = "https://api.x.com/2/users/me".freeze
      POSTS_URL = "https://api.x.com/2/tweets".freeze

      def requires_pkce?
        true
      end

      def authorization_url(redirect_uri:, state:, code_verifier:)
        auth_query(
          AUTH_URL,
          response_type: "code",
          client_id: client_id,
          redirect_uri: redirect_uri,
          state: state,
          scope: scopes.join(" "),
          code_challenge: code_challenge_for(code_verifier),
          code_challenge_method: "S256"
        )
      end

      def connect_account_attributes(code:, redirect_uri:, code_verifier:)
        token_data = post_form(
          TOKEN_URL,
          body: {
            code: code,
            grant_type: "authorization_code",
            redirect_uri: redirect_uri,
            code_verifier: code_verifier,
            client_id: client_id
          },
          headers: basic_auth_header
        )

        profile = get_json(
          ME_URL,
          params: { "user.fields" => "id,name,username,profile_image_url" },
          headers: bearer_header(token_data.fetch("access_token"))
        ).fetch("data")

        {
          external_uid: profile.fetch("id"),
          username: profile["username"],
          access_token: token_data.fetch("access_token"),
          refresh_token: token_data["refresh_token"],
          expires_at: expires_at_from(token_data["expires_in"]),
          active: true,
          connected_at: Time.current,
          last_synced_at: Time.current,
          metadata: {
            "name" => profile["name"],
            "profile_image_url" => profile["profile_image_url"]
          }
        }
      end

      def publish!(account:, draft:)
        refresh_account!(account) if account.expired?

        response = post_json(
          POSTS_URL,
          body: { text: draft.body },
          headers: bearer_header(account.access_token)
        )

        remote_id = response.dig("data", "id")
        url = remote_id.present? && account.username.present? ? "https://x.com/#{account.username}/status/#{remote_id}" : nil
        { remote_id: remote_id || "x-post", url: url }
      end

      private

      def refresh_account!(account)
        raise Social::Error, "X access has expired. Reconnect the account to continue." if account.refresh_token.blank?

        token_data = post_form(
          TOKEN_URL,
          body: {
            refresh_token: account.refresh_token,
            grant_type: "refresh_token",
            client_id: client_id
          },
          headers: basic_auth_header
        )

        account.update!(
          access_token: token_data.fetch("access_token"),
          refresh_token: token_data["refresh_token"].presence || account.refresh_token,
          expires_at: expires_at_from(token_data["expires_in"]),
          last_synced_at: Time.current
        )
      end

      def scopes
        %w[tweet.read tweet.write users.read offline.access]
      end

      def client_id
        ENV["X_CLIENT_ID"]
      end

      def client_secret
        ENV["X_CLIENT_SECRET"]
      end
    end
  end
end

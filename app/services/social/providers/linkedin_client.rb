module Social
  module Providers
    class LinkedinClient < BaseClient
      AUTH_URL = "https://www.linkedin.com/oauth/v2/authorization".freeze
      TOKEN_URL = "https://www.linkedin.com/oauth/v2/accessToken".freeze
      USERINFO_URL = "https://api.linkedin.com/v2/userinfo".freeze
      POSTS_URL = "https://api.linkedin.com/rest/posts".freeze
      LINKEDIN_VERSION = "202603".freeze

      def authorization_url(redirect_uri:, state:, code_verifier: nil)
        auth_query(
          AUTH_URL,
          response_type: "code",
          client_id: client_id,
          redirect_uri: redirect_uri,
          state: state,
          scope: scopes.join(" ")
        )
      end

      def connect_account_attributes(code:, redirect_uri:, code_verifier: nil)
        token_data = exchange_code(code: code, redirect_uri: redirect_uri)
        profile = fetch_profile(access_token: token_data.fetch("access_token"))

        {
          external_uid: profile.fetch("sub"),
          username: profile["email"].presence || profile["name"],
          access_token: token_data.fetch("access_token"),
          refresh_token: token_data["refresh_token"],
          expires_at: expires_at_from(token_data["expires_in"]),
          active: true,
          connected_at: Time.current,
          last_synced_at: Time.current,
          metadata: {
            "name" => profile["name"],
            "email" => profile["email"],
            "picture" => profile["picture"]
          }
        }
      end

      def publish!(account:, draft:)
        raise Social::Error, "LinkedIn access has expired. Reconnect the account to publish again." if account.expired?

        response = post_json(
          POSTS_URL,
          body: {
            author: "urn:li:person:#{account.external_uid}",
            commentary: draft.body,
            visibility: "PUBLIC",
            distribution: {
              feedDistribution: "MAIN_FEED",
              targetEntities: [],
              thirdPartyDistributionChannels: []
            },
            lifecycleState: "PUBLISHED",
            isReshareDisabledByAuthor: false
          },
          headers: bearer_header(account.access_token).merge(
            "X-Restli-Protocol-Version" => "2.0.0",
            "Linkedin-Version" => LINKEDIN_VERSION
          )
        )

        remote_id = response["id"].presence || response["x-restli-id"]
        { remote_id: remote_id || "linkedin-post", url: nil }
      end

      private

      def exchange_code(code:, redirect_uri:)
        post_form(
          TOKEN_URL,
          body: {
            grant_type: "authorization_code",
            code: code,
            redirect_uri: redirect_uri,
            client_id: client_id,
            client_secret: client_secret
          }
        )
      end

      def fetch_profile(access_token:)
        get_json(USERINFO_URL, headers: bearer_header(access_token))
      end

      def scopes
        %w[openid profile email w_member_social]
      end

      def client_id
        ENV["LINKEDIN_CLIENT_ID"]
      end

      def client_secret
        ENV["LINKEDIN_CLIENT_SECRET"]
      end
    end
  end
end

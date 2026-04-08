require "base64"
require "digest"
require "json"
require "securerandom"

module Social
  module Providers
    class BaseClient
      def configured?
        client_id.present? && client_secret.present?
      end

      def requires_pkce?
        false
      end

      def supports_text_only_posts?
        true
      end

      def generate_code_verifier
        SecureRandom.urlsafe_base64(48)
      end

      private

      def expires_at_from(seconds)
        return if seconds.blank?

        seconds.to_i.seconds.from_now
      end

      def code_challenge_for(verifier)
        Base64.urlsafe_encode64(Digest::SHA256.digest(verifier.to_s), padding: false)
      end

      def basic_auth_header
        token = Base64.strict_encode64("#{client_id}:#{client_secret}")
        { "Authorization" => "Basic #{token}" }
      end

      def bearer_header(token)
        { "Authorization" => "Bearer #{token}" }
      end

      def get_json(url, params: {}, headers: {})
        response = Faraday.get(url) do |request|
          request.params.update(params.compact)
          headers.each { |key, value| request.headers[key] = value }
        end

        parse_response(response)
      end

      def post_json(url, body:, headers: {})
        response = Faraday.post(url) do |request|
          request.headers["Content-Type"] = "application/json"
          headers.each { |key, value| request.headers[key] = value }
          request.body = JSON.dump(body.compact)
        end

        parse_response(response)
      end

      def post_form(url, body:, headers: {})
        response = Faraday.post(url) do |request|
          request.headers["Content-Type"] = "application/x-www-form-urlencoded"
          headers.each { |key, value| request.headers[key] = value }
          request.body = URI.encode_www_form(body.compact)
        end

        parse_response(response)
      end

      def parse_response(response)
        payload =
          begin
            response.body.present? ? JSON.parse(response.body) : {}
          rescue JSON::ParserError
            {}
          end

        return payload if response.success?

        message =
          payload["error_description"] ||
          payload["message"] ||
          payload.dig("error", "message") ||
          payload["error"] ||
          response.body.to_s.truncate(180)

        raise Social::Error, "#{provider_name} request failed: #{message}"
      end

      def auth_query(base_url, params)
        uri = URI.parse(base_url)
        uri.query = URI.encode_www_form(params.compact)
        uri.to_s
      end

      def provider_name
        self.class.name.demodulize.sub("Client", "").titleize
      end
    end
  end
end

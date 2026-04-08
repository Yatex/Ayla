module Social
  class Publisher < ApplicationService
    ResultItem = Struct.new(:provider, :remote_id, :message, :url, keyword_init: true)
    Result = Struct.new(:successes, :failures, keyword_init: true) do
      def summary
        parts = []
        parts << "Published to #{successes.map(&:provider).map { |provider| provider.to_s.titleize }.join(', ')}." if successes.any?
        parts << failures.map(&:message).join(" ") if failures.any?
        parts.join(" ").strip
      end
    end

    def initialize(draft:, user:, providers:)
      @draft = draft
      @user = user
      @providers = Array(providers)
    end

    def call
      raise Social::Error, "Choose at least one connected platform to publish this draft." if providers.blank?

      successes = []
      failures = []

      providers.each do |provider|
        account = user.social_accounts.connected.find_by(provider: provider)
        unless account
          failures << ResultItem.new(provider: provider, message: "#{provider.titleize} is not connected.")
          next
        end

        begin
          result = Social::ProviderRegistry.fetch(provider).publish!(account: account, draft: draft)
          successes << ResultItem.new(provider: provider, remote_id: result[:remote_id], url: result[:url], message: "#{provider.titleize} published.")
          draft.store_published_post(
            provider: provider,
            payload: {
              "remote_id" => result[:remote_id],
              "url" => result[:url],
              "published_at" => Time.current.iso8601
            }
          )
        rescue Social::Error => e
          failures << ResultItem.new(provider: provider, message: e.message)
        end
      end

      persist_successes(successes) if successes.any?

      Result.new(successes: successes, failures: failures)
    end

    private

    attr_reader :draft, :user, :providers

    def persist_successes(successes)
      published_platforms = (draft.platform.to_s.split(",").map(&:strip).reject(&:blank?) + successes.map(&:provider)).uniq
      draft.update!(
        platform: published_platforms.join(", "),
        posted_at: Time.current,
        metadata: draft.metadata
      )
    end
  end
end

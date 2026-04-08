module Social
  class ProviderRegistry
    PROVIDERS = {
      "instagram" => Social::Providers::InstagramClient,
      "linkedin" => Social::Providers::LinkedinClient,
      "x" => Social::Providers::XClient
    }.freeze

    def self.fetch(provider)
      klass = PROVIDERS[provider.to_s]
      raise ArgumentError, "Unsupported provider: #{provider}" unless klass

      klass.new
    end

    def self.providers
      PROVIDERS.keys
    end
  end
end

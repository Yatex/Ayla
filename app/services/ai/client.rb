module Ai
  class Client < ApplicationService
    def initialize(prompt:, model: nil)
      @prompt = prompt
      @model = model || "gpt-4o-mini"
    end

    def call
      # Placeholder: returns a simulated response for development.
      # Replace with real OpenAI/LLM API call when ready.
      if Rails.env.production? || ENV["OPENAI_API_KEY"].present?
        call_openai
      else
        simulate_response
      end
    end

    private

    def call_openai
      conn = Faraday.new(url: "https://api.openai.com") do |f|
        f.request :json
        f.response :json
        f.adapter Faraday.default_adapter
      end

      response = conn.post("/v1/chat/completions") do |req|
        req.headers["Authorization"] = "Bearer #{ENV['OPENAI_API_KEY']}"
        req.body = {
          model: @model,
          messages: @prompt,
          max_tokens: 500,
          temperature: 0.7
        }
      end

      response.body.dig("choices", 0, "message", "content") || "Sorry, I couldn't generate a draft right now."
    end

    def simulate_response
      context_text = @prompt.select { |m| m[:role] == "user" }.map { |m| m[:content] }.join(" ")
      "[DEV MODE] Draft based on: #{context_text.truncate(100)}\n\n" \
      "This is a simulated draft. Connect an OpenAI API key to generate real content."
    end
  end
end

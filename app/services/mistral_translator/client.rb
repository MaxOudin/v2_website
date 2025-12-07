# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module MistralTranslator
  # Client pour l'API Mistral
  class Client
    class ApiError < StandardError; end
    class AuthenticationError < ApiError; end
    class RateLimitError < ApiError; end
    class InvalidResponseError < ApiError; end

    def initialize(api_key: nil, api_url: nil, model: nil)
      @api_key = api_key || MistralTranslator.configuration.api_key!
      @api_url = api_url || MistralTranslator.configuration.api_url
      @model = model || MistralTranslator.configuration.model
      @retry_delays = MistralTranslator.configuration.retry_delays
    end

    def translate(text, from:, to:, context: nil, glossary: nil)
      Rails.logger.info("[MistralTranslator::Client] Traduction de #{text.length} caractères (#{from} → #{to})")
      prompt = build_translation_prompt(text, from, to, context: context, glossary: glossary)
      response = make_request_with_retry(prompt)
      translated = extract_translation(response)
      Rails.logger.info("[MistralTranslator::Client] Traduction terminée : #{translated.length} caractères")
      translated
    end

    private

    def build_translation_prompt(text, from, to, context: nil, glossary: nil)
      parts = []
      parts << "Traduis le texte suivant du #{from} vers le #{to}."
      
      if context
        parts << "\nCONTEXTE : #{context}"
      end

      if glossary.is_a?(Hash) && glossary.any?
        glossary_text = glossary.map { |k, v| "#{k} → #{v}" }.join(", ")
        parts << "\nGLOSSAIRE (à respecter strictement) : #{glossary_text}"
      elsif glossary.is_a?(String) && !glossary.strip.empty?
        parts << "\nGLOSSAIRE : #{glossary}"
      end

      parts << "\n\nTEXTE À TRADUIRE :"
      parts << text
      parts << "\n\nRÈGLES :"
      parts << "- Préserve le formatage HTML si présent"
      parts << "- Respecte le style et le ton du texte original"
      parts << "- Réponds uniquement avec la traduction, sans commentaires"

      parts.join("\n")
    end

    def make_request_with_retry(prompt, attempt = 0)
      response = make_request(prompt)
      handle_response(response)
    rescue RateLimitError => e
      if attempt < @retry_delays.length
        wait_time = @retry_delays[attempt]
        Rails.logger.warn("[MistralTranslator] Rate limit, attente de #{wait_time}s (tentative #{attempt + 1})") if defined?(Rails)
        sleep(wait_time)
        make_request_with_retry(prompt, attempt + 1)
      else
        raise e
      end
    end

    def make_request(prompt)
      uri = URI("#{@api_url}/v1/chat/completions")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 60

      request = Net::HTTP::Post.new(uri.path, headers)
      request.body = {
        model: @model,
        messages: [
          {
            role: "user",
            content: prompt
          }
        ],
        temperature: MistralTranslator.configuration.default_temperature
      }.to_json

      response = http.request(request)
      response
    rescue Net::ReadTimeout, Timeout::Error => e
      raise ApiError, "Timeout de la requête : #{e.message}"
    rescue Net::HTTPError => e
      raise ApiError, "Erreur HTTP : #{e.message}"
    end

    def handle_response(response)
      case response.code.to_i
      when 401
        raise AuthenticationError, "Clé API invalide"
      when 429
        raise RateLimitError, "Limite de taux dépassée"
      when 400..499
        raise ApiError, "Erreur client (#{response.code})"
      when 500..599
        raise ApiError, "Erreur serveur (#{response.code})"
      end

      response
    end

    def extract_translation(response)
      body = JSON.parse(response.body)
      content = body.dig("choices", 0, "message", "content")
      
      raise InvalidResponseError, "Réponse invalide de l'API" if content.nil? || content.empty?

      # Nettoyer la réponse (enlever les guillemets si présents)
      content.strip.gsub(/^["']|["']$/, "")
    rescue JSON::ParserError => e
      raise InvalidResponseError, "Erreur de parsing JSON : #{e.message}"
    end

    def headers
      {
        "Authorization" => "Bearer #{@api_key}",
        "Content-Type" => "application/json"
      }
    end
  end
end


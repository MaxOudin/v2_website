# frozen_string_literal: true

module MistralTranslator
  # Service principal de traduction
  class TranslationService
    def initialize(client: nil)
      @client = client || Client.new
    end

    # Traduit un texte simple
    def translate_text(text, from:, to:, context: nil, glossary: nil)
      return "" if text.nil? || text.to_s.strip.empty?
      return text.to_s if from.to_s == to.to_s

      @client.translate(text.to_s, from: from.to_s, to: to.to_s, context: context, glossary: glossary)
    rescue Client::ApiError => e
      Rails.logger.error("[MistralTranslator] Erreur lors de la traduction : #{e.message}") if defined?(Rails)
      raise
    end

    # Traduit un texte HTML (rich text)
    def translate_html(html_content, from:, to:, context: nil, glossary: nil)
      return "" if html_content.nil? || html_content.to_s.strip.empty?
      return html_content.to_s if from.to_s == to.to_s

      # Extraire le texte brut pour la traduction
      plain_text = extract_plain_text(html_content)
      return html_content.to_s if plain_text.strip.empty?

      # Traduire le texte
      translated_text = translate_text(plain_text, from: from, to: to, context: context, glossary: glossary)

      # Préserver la structure HTML si possible
      preserve_html_structure(html_content, plain_text, translated_text)
    rescue Client::ApiError => e
      Rails.logger.error("[MistralTranslator] Erreur lors de la traduction HTML : #{e.message}") if defined?(Rails)
      raise
    end

    private

    def extract_plain_text(html_content)
      # Si c'est déjà du texte brut, le retourner tel quel
      return html_content.to_s unless html_content.to_s.match?(/<[^>]+>/)

      # Extraire le texte des balises HTML
      html_content.to_s.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ").strip
    end

    def preserve_html_structure(original_html, original_text, translated_text)
      # Pour l'instant, on retourne simplement le texte traduit
      # Une version plus sophistiquée pourrait préserver les balises HTML
      # mais cela nécessiterait un parsing plus complexe
      translated_text
    end
  end
end

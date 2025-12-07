# frozen_string_literal: true

# Configuration pour le service de traduction Mistral
module MistralTranslator
  class Configuration
    attr_accessor :api_key, :api_url, :model, :default_max_tokens, :default_temperature,
                  :retry_delays, :enable_metrics, :rate_limit_delay

    def initialize
      @api_key = ENV["MISTRAL_API_KEY"]
      @api_url = "https://api.mistral.ai"
      @model = "mistral-small"
      @default_max_tokens = nil
      @default_temperature = 0.3
      @retry_delays = [2, 4, 8, 16]
      @enable_metrics = false
      @rate_limit_delay = 2 # Délai en secondes entre les requêtes
    end

    def api_key!
      raise "MISTRAL_API_KEY n'est pas définie. Définissez-la dans votre fichier .env ou dans les variables d'environnement." if @api_key.nil? || @api_key.empty?

      @api_key
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end
  end
end

# Configuration par défaut
MistralTranslator.configure do |config|
  # La clé API sera lue depuis ENV["MISTRAL_API_KEY"]
  # Vous pouvez surcharger ici si nécessaire
end

# Les services sont chargés automatiquement par Zeitwerk
# Pas besoin de require_dependency avec la structure de dossiers correcte


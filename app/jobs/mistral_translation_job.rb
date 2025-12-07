# frozen_string_literal: true

# Job pour traduire un enregistrement de manière asynchrone
class MistralTranslationJob < ApplicationJob
  queue_as :default

  # Retry en cas d'erreur de rate limit
  retry_on MistralTranslator::Client::RateLimitError, wait: :polynomially_longer, attempts: 5

  def perform(record_class, record_id, options = {})
    Rails.logger.info("[MistralTranslationJob] Démarrage de la traduction pour #{record_class}##{record_id}")
    
    record = record_class.constantize.find(record_id)

    # Inclure le concern si nécessaire
    record.class.include(MistralTranslatable) unless record.class.included_modules.include?(MistralTranslatable)

    # Traduire l'enregistrement
    results = record.translate_with_mistral!(options)
    
    mobility_count = results[:mobility].size
    rich_text_count = results[:rich_text].size
    total = mobility_count + rich_text_count
    
    Rails.logger.info("[MistralTranslationJob] Traduction terminée : #{total} champ(s) traduit(s) (#{mobility_count} Mobility, #{rich_text_count} RichText)")
    
    results
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("[MistralTranslationJob] Enregistrement non trouvé : #{record_class}##{record_id}")
    raise e
  rescue StandardError => e
    Rails.logger.error("[MistralTranslationJob] Erreur lors de la traduction : #{e.message}")
    Rails.logger.error("[MistralTranslationJob] Backtrace: #{e.backtrace.first(5).join("\n")}")
    raise e
  end
end


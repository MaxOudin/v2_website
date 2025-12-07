# frozen_string_literal: true

module MistralTranslator
  # Service de traduction pour les modèles utilisant Mobility (string, text)
  class MobilityTranslationService
    def initialize(translation_service: nil)
      @translation_service = translation_service || TranslationService.new
    end

    # Traduit tous les champs Mobility d'un enregistrement
    def translate_record(record, fields:, from: nil, to: nil, context: nil, glossary: nil, force: false)
      from ||= I18n.default_locale
      to ||= I18n.available_locales.reject { |l| l == from }

      target_locales = Array(to)
      source_locale = from.to_sym

      # Vérifier que le record utilise Mobility
      unless record.class.respond_to?(:mobility_attributes)
        raise ArgumentError, "Le modèle #{record.class.name} n'utilise pas Mobility"
      end

      translated_fields = []
      target_locales.each do |target_locale|
        next if source_locale == target_locale.to_sym

        Array(fields).each do |field|
          next unless record.class.mobility_attributes.include?(field.to_sym)

          source_value = record.public_send("#{field}_#{source_locale}")
          if source_value.nil? || source_value.to_s.strip.empty?
            Rails.logger.debug("[MistralTranslator] Pas de contenu source pour #{field} (#{source_locale})")
            next
          end

          # Vérifier si la traduction existe déjà (sauf si on force ou si elle est vide)
          existing_translation = record.public_send("#{field}_#{target_locale}")
          if !force && existing_translation.present? && existing_translation.to_s.strip.present?
            Rails.logger.debug("[MistralTranslator] Traduction existante pour #{field} (#{target_locale}), ignorée")
            next
          end

          Rails.logger.info("[MistralTranslator] Traduction de #{field} (#{source_locale} → #{target_locale})")

          begin
            translated_value = @translation_service.translate_text(
              source_value,
              from: source_locale.to_s,
              to: target_locale.to_s,
              context: context,
              glossary: glossary
            )

            record.public_send("#{field}_#{target_locale}=", translated_value)
            translated_fields << { field: field, locale: target_locale }
          rescue StandardError => e
            Rails.logger.error(
              "[MistralTranslator] Erreur lors de la traduction de #{field} (#{source_locale} → #{target_locale}) : #{e.message}"
            ) if defined?(Rails)
          end

          # Rate limiting
          sleep(MistralTranslator.configuration.rate_limit_delay)
        end
      end

      translated_fields
    end

    # Traduit un champ spécifique
    def translate_field(record, field:, from:, to:, context: nil, glossary: nil)
      source_value = record.public_send("#{field}_#{from}")
      return nil if source_value.nil? || source_value.to_s.strip.empty?

      translated_value = @translation_service.translate_text(
        source_value,
        from: from.to_s,
        to: to.to_s,
        context: context,
        glossary: glossary
      )

      record.public_send("#{field}_#{to}=", translated_value)
      translated_value
    rescue StandardError => e
      Rails.logger.error(
        "[MistralTranslator] Erreur lors de la traduction de #{field} (#{from} → #{to}) : #{e.message}"
      ) if defined?(Rails)
      raise
    end
  end
end

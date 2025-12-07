# frozen_string_literal: true

module MistralTranslator
  # Service de traduction pour les champs RichText (ActionText)
  class RichTextTranslationService
    def initialize(translation_service: nil)
      @translation_service = translation_service || TranslationService.new
    end

    # Traduit tous les champs RichText d'un enregistrement
    def translate_record(record, fields:, from: nil, to: nil, context: nil, glossary: nil, force: false)
      from ||= I18n.default_locale
      to ||= I18n.available_locales.reject { |l| l == from }

      target_locales = Array(to)
      source_locale = from.to_sym

      # Vérifier que le record utilise TranslatableRichText
      unless record.class.respond_to?(:translated_rich_text_fields)
        raise ArgumentError, "Le modèle #{record.class.name} n'utilise pas TranslatableRichText"
      end

      translated_fields = []
      target_locales.each do |target_locale|
        next if source_locale == target_locale.to_sym

        Array(fields).each do |field|
          # Récupérer le contenu source
          source_content = get_rich_text_content(record, field, source_locale)
          if source_content.nil? || source_content.to_s.strip.empty?
            Rails.logger.debug("[MistralTranslator] Pas de contenu source pour #{field} (#{source_locale})")
            next
          end

          # Vérifier si la traduction existe déjà (sauf si on force ou si elle est vide)
          existing_translation = get_rich_text_content(record, field, target_locale.to_sym)
          if !force && existing_translation.present? && existing_translation.to_s.strip.present?
            Rails.logger.debug("[MistralTranslator] Traduction existante pour #{field} (#{target_locale}), ignorée")
            next
          end

          Rails.logger.info("[MistralTranslator] Traduction de #{field} (#{source_locale} → #{target_locale})")

          begin
            # Traduire le contenu HTML
            translated_content = @translation_service.translate_html(
              source_content,
              from: source_locale.to_s,
              to: target_locale.to_s,
              context: context,
              glossary: glossary
            )

            # Sauvegarder la traduction
            set_rich_text_content(record, field, target_locale.to_sym, translated_content)
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

    # Traduit un champ RichText spécifique
    def translate_field(record, field:, from:, to:, context: nil, glossary: nil)
      source_content = get_rich_text_content(record, field, from)
      return nil if source_content.nil? || source_content.to_s.strip.empty?

      translated_content = @translation_service.translate_html(
        source_content,
        from: from.to_s,
        to: to.to_s,
        context: context,
        glossary: glossary
      )

      set_rich_text_content(record, field, to, translated_content)
      translated_content
    rescue StandardError => e
      Rails.logger.error(
        "[MistralTranslator] Erreur lors de la traduction de #{field} (#{from} → #{to}) : #{e.message}"
      ) if defined?(Rails)
      raise
    end

    private

    def get_rich_text_content(record, field, locale)
      # Vérifier d'abord les traductions en attente
      if record.instance_variable_get(:@pending_translations)
        pending = record.instance_variable_get(:@pending_translations)[[field.to_sym, locale.to_sym]]
        return pending if pending.present? && pending.to_s.strip.present?
      end

      # Sinon, chercher dans la base de données
      rich_text = record.translated_rich_texts.find_by(field_name: field.to_s, locale: locale.to_s)
      return nil unless rich_text&.body

      # Utiliser to_plain_text d'ActionText pour vérifier si le contenu est vraiment vide
      # (c'est plus fiable que d'extraire manuellement le texte des balises HTML)
      plain_text = rich_text.body.to_plain_text
      return nil if plain_text.strip.empty?

      # Retourner le HTML complet pour la traduction
      rich_text.body.to_s
    end

    def set_rich_text_content(record, field, locale, content)
      # Initialiser @pending_translations si nécessaire
      record.instance_variable_set(:@pending_translations, {}) unless record.instance_variable_get(:@pending_translations)

      # Stocker dans les traductions en attente avec la clé [field, locale]
      record.instance_variable_get(:@pending_translations)[[field.to_sym, locale.to_sym]] = content

      # Si l'enregistrement est déjà sauvegardé, sauvegarder immédiatement
      if record.persisted?
        rich_text = record.translated_rich_texts.find_or_initialize_by(
          field_name: field.to_s,
          locale: locale.to_s
        )
        rich_text.body = content
        rich_text.save
      end
    end
  end
end


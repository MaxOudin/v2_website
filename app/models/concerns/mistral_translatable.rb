# frozen_string_literal: true

# Concern pour ajouter des méthodes de traduction aux modèles
module MistralTranslatable
  extend ActiveSupport::Concern

  included do
    # Méthode pour traduire automatiquement tous les champs traduisibles
    def translate_with_mistral!(options = {})
      Rails.logger.info("[MistralTranslatable] Démarrage de la traduction pour #{self.class.name}##{id}")
      
      service = MistralTranslator::MistralTranslatorService.new
      results = service.translate_record(self, options)

      mobility_count = results[:mobility].size
      rich_text_count = results[:rich_text].size
      total = mobility_count + rich_text_count
      
      Rails.logger.info("[MistralTranslatable] #{total} champ(s) traduit(s) (#{mobility_count} Mobility, #{rich_text_count} RichText)")

      # Sauvegarder les modifications
      if changed?
        save!
        Rails.logger.info("[MistralTranslatable] Modifications sauvegardées")
      else
        Rails.logger.debug("[MistralTranslatable] Aucune modification à sauvegarder")
      end

      results
    end

    # Méthode pour traduire uniquement les champs Mobility
    def translate_mobility_fields!(fields:, from: nil, to: nil, context: nil, glossary: nil)
      service = MistralTranslator::MobilityTranslationService.new
      results = service.translate_record(
        self,
        fields: fields,
        from: from,
        to: to,
        context: context,
        glossary: glossary
      )

      save! if changed?
      results
    end

    # Méthode pour traduire uniquement les champs RichText
    def translate_rich_text_fields!(fields:, from: nil, to: nil, context: nil, glossary: nil)
      service = MistralTranslator::RichTextTranslationService.new
      results = service.translate_record(
        self,
        fields: fields,
        from: from,
        to: to,
        context: context,
        glossary: glossary
      )

      save! if changed?
      results
    end

    # Méthode pour traduire un champ Mobility spécifique
    def translate_mobility_field!(field:, from:, to:, context: nil, glossary: nil)
      service = MistralTranslator::MobilityTranslationService.new
      result = service.translate_field(
        self,
        field: field,
        from: from,
        to: to,
        context: context,
        glossary: glossary
      )

      save! if changed?
      result
    end

    # Méthode pour traduire un champ RichText spécifique
    def translate_rich_text_field!(field:, from:, to:, context: nil, glossary: nil)
      service = MistralTranslator::RichTextTranslationService.new
      result = service.translate_field(
        self,
        field: field,
        from: from,
        to: to,
        context: context,
        glossary: glossary
      )

      save! if changed?
      result
    end
  end
end

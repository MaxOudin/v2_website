# frozen_string_literal: true

module MistralTranslator
  # Service principal qui orchestre les traductions
  class MistralTranslatorService
    def initialize
      @translation_service = TranslationService.new
      @mobility_service = MobilityTranslationService.new(translation_service: @translation_service)
      @rich_text_service = RichTextTranslationService.new(translation_service: @translation_service)
    end

    # Traduit un enregistrement complet (Mobility + RichText)
    def translate_record(record, options = {})
      from = options[:from] || I18n.default_locale
      to = options[:to] || I18n.available_locales.reject { |l| l == from }
      context = options[:context]
      glossary = options[:glossary]
      force = options[:force] || false
      fields = options[:fields] || detect_translatable_fields(record)

      results = {
        mobility: [],
        rich_text: []
      }

      # Séparer les champs Mobility et RichText
      mobility_fields = []
      rich_text_fields = []

      fields.each do |field|
        if is_mobility_field?(record, field)
          mobility_fields << field
        elsif is_rich_text_field?(record, field)
          rich_text_fields << field
        end
      end

      # Traduire les champs Mobility
      if mobility_fields.any?
        results[:mobility] = @mobility_service.translate_record(
          record,
          fields: mobility_fields,
          from: from,
          to: to,
          context: context,
          glossary: glossary,
          force: force
        )
      end

      # Traduire les champs RichText
      if rich_text_fields.any?
        results[:rich_text] = @rich_text_service.translate_record(
          record,
          fields: rich_text_fields,
          from: from,
          to: to,
          context: context,
          glossary: glossary,
          force: force
        )
      end

      results
    end

    # Traduit uniquement les champs Mobility
    def translate_mobility_fields(record, fields:, from: nil, to: nil, context: nil, glossary: nil)
      @mobility_service.translate_record(
        record,
        fields: fields,
        from: from,
        to: to,
        context: context,
        glossary: glossary
      )
    end

    # Traduit uniquement les champs RichText
    def translate_rich_text_fields(record, fields:, from: nil, to: nil, context: nil, glossary: nil)
      @rich_text_service.translate_record(
        record,
        fields: fields,
        from: from,
        to: to,
        context: context,
        glossary: glossary
      )
    end

    # Traduit un texte simple
    def translate_text(text, from:, to:, context: nil, glossary: nil)
      @translation_service.translate_text(
        text,
        from: from,
        to: to,
        context: context,
        glossary: glossary
      )
    end

    private

    def detect_translatable_fields(record)
      fields = []

      # Détecter les champs Mobility
      if record.class.respond_to?(:mobility_attributes)
        fields.concat(record.class.mobility_attributes.map(&:to_s))
      end

      # Détecter les champs RichText
      if record.class.respond_to?(:translated_rich_text_fields)
        fields.concat(record.class.translated_rich_text_fields.map(&:to_s))
      end

      fields
    end

    def is_mobility_field?(record, field)
      return false unless record.class.respond_to?(:mobility_attributes)

      record.class.mobility_attributes.include?(field.to_sym)
    end

    def is_rich_text_field?(record, field)
      return false unless record.class.respond_to?(:translated_rich_text_fields)

      record.class.translated_rich_text_fields.include?(field.to_sym)
    end
  end
end

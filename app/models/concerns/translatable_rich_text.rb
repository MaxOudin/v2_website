# app/models/concerns/translatable_rich_text.rb
module TranslatableRichText
  extend ActiveSupport::Concern

  included do
    # Initialisation du hash des traductions en attente
    after_initialize do
      @pending_translations = {}
    end

    # Sauvegarde des traductions après la création/mise à jour de l'enregistrement principal
    after_save :save_pending_translations
  end

  def save_pending_translations
    return if @pending_translations.blank?

    @pending_translations.each do |locale, content|
      rich_text = translated_rich_texts.find_or_initialize_by(
        field_name: self.class.translation_field_name,
        locale: locale
      )
      rich_text.body = content
      rich_text.save
    end
    @pending_translations = {}
  end

  class_methods do
    attr_reader :translation_field_name

    def has_translated_rich_text(field_name)
      extend Mobility

      # Stocke le nom du champ pour l'utiliser dans les callbacks
      @translation_field_name = field_name

      # Configuration Mobility pour le champ
      translates field_name, type: :string

      # Association avec ActionText
      has_many :translated_rich_texts, as: :record, class_name: 'TranslatedRichText', dependent: :destroy

      # Définition des méthodes d'accès avec fallbacks
      I18n.available_locales.each do |locale|
        define_method("#{field_name}_#{locale}") do
          @pending_translations ||= {}
          # Vérifie d'abord les traductions en attente
          pending_content = @pending_translations[locale]
          return pending_content if pending_content.present?

          # Sinon, cherche dans la base de données
          content = translated_rich_texts.find_by(field_name: field_name, locale: locale)&.body

          # Gestion des fallbacks si le contenu est nil
          if content.nil? && I18n.fallbacks[locale].present?
            I18n.fallbacks[locale].each do |fallback_locale|
              next if fallback_locale == locale
              fallback_content = translated_rich_texts.find_by(
                field_name: field_name,
                locale: fallback_locale
              )&.body
              return fallback_content if fallback_content.present?
            end
          end

          content
        end

        define_method("#{field_name}_#{locale}=") do |content|
          @pending_translations ||= {}
          @pending_translations[locale] = content
        end
      end

      # Helper pour accéder au contenu dans la locale courante
      define_method(field_name) do
        public_send("#{field_name}_#{I18n.locale}")
      end

      define_method("#{field_name}=") do |content|
        public_send("#{field_name}_#{I18n.locale}=", content)
      end
    end
  end
end

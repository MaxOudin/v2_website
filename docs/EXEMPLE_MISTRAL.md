# Exemples d'utilisation du service Mistral Translator

## Configuration initiale

1. Ajoutez votre clé API Mistral dans votre fichier `.env` :
```bash
MISTRAL_API_KEY=votre_cle_api_ici
```

2. Testez la connexion :
```bash
rake mistral_translator:test_connection
```

## Exemples d'utilisation

### Exemple 1 : Traduction simple d'un texte

```ruby
# Dans la console Rails
service = MistralTranslator::TranslationService.new

result = service.translate_text(
  "Bonjour le monde",
  from: "fr",
  to: "en"
)
# => "Hello world"
```

### Exemple 2 : Traduction d'un projet complet

```ruby
# Récupérer un projet
project = Project.find(1)

# Traduire tous les champs traduisibles (title, description, context)
# depuis le français vers l'anglais
results = project.translate_with_mistral!(
  from: :fr,
  to: [:en],
  context: "projet de développement web"
)

# Les résultats contiennent :
# {
#   mobility: [{ field: :title, locale: :en }, { field: :description, locale: :en }],
#   rich_text: [{ field: :context, locale: :en }]
# }
```

### Exemple 3 : Traduction uniquement des champs Mobility

```ruby
project = Project.find(1)

# Traduire uniquement title et description
results = project.translate_mobility_fields!(
  fields: [:title, :description],
  from: :fr,
  to: [:en],
  context: "titre et description de projet"
)
```

### Exemple 4 : Traduction uniquement des champs RichText

```ruby
project = Project.find(1)

# Traduire uniquement le champ context
results = project.translate_rich_text_fields!(
  fields: [:context],
  from: :fr,
  to: [:en],
  context: "description détaillée du projet"
)
```

### Exemple 5 : Traduction avec glossaire

```ruby
project = Project.find(1)

# Définir un glossaire pour préserver certains termes
glossary = {
  "Rails" => "Rails",
  "API" => "API",
  "PostgreSQL" => "PostgreSQL"
}

project.translate_with_mistral!(
  from: :fr,
  to: [:en],
  context: "projet technique",
  glossary: glossary
)
```

### Exemple 6 : Traduction asynchrone

```ruby
# Dans un contrôleur ou un service
project = Project.create!(title_fr: "Mon Projet", description_fr: "Description...")

# Lancer la traduction en arrière-plan
MistralTranslationJob.perform_later(
  "Project",
  project.id,
  {
    from: :fr,
    to: [:en],
    context: "projet de développement web"
  }
)
```

### Exemple 7 : Traduction automatique après création

```ruby
# Dans le modèle Project
class Project < ApplicationRecord
  include Mobility
  include TranslatableRichText
  include MistralTranslatable

  after_create :auto_translate, if: :should_auto_translate?

  private

  def should_auto_translate?
    Rails.env.production? && ENV["AUTO_TRANSLATE"] == "true"
  end

  def auto_translate
    MistralTranslationJob.perform_later(
      "Project",
      id,
      {
        from: I18n.default_locale,
        to: [:en],
        context: "projet de développement web"
      }
    )
  end
end
```

### Exemple 8 : Traduction en masse avec Rake

```bash
# Traduire tous les projets
rake mistral_translator:translate_projects

# Traduire un projet spécifique
rake mistral_translator:translate_project[123]
```

### Exemple 9 : Utilisation dans un contrôleur

```ruby
class ProjectsController < ApplicationController
  def create
    @project = Project.new(project_params)
    
    if @project.save
      # Option 1 : Traduction synchrone (bloquante)
      if params[:translate_now] == "true"
        @project.translate_with_mistral!(
          from: :fr,
          to: [:en],
          context: "projet de développement web"
        )
        flash[:notice] = "Projet créé et traduit avec succès"
      else
        # Option 2 : Traduction asynchrone (recommandée)
        MistralTranslationJob.perform_later(
          "Project",
          @project.id,
          {
            from: :fr,
            to: [:en],
            context: "projet de développement web"
          }
        )
        flash[:notice] = "Projet créé, traduction en cours..."
      end
      
      redirect_to @project
    else
      render :new
    end
  end
end
```

### Exemple 10 : Traduction conditionnelle

```ruby
project = Project.find(1)

# Vérifier quelles traductions manquent
missing_translations = []

I18n.available_locales.each do |locale|
  next if locale == I18n.default_locale
  
  # Vérifier les champs Mobility
  [:title, :description].each do |field|
    value = project.public_send("#{field}_#{locale}")
    missing_translations << { field: field, locale: locale } if value.blank?
  end
  
  # Vérifier les champs RichText
  [:context].each do |field|
    value = project.public_send("#{field}_#{locale}")
    missing_translations << { field: field, locale: locale } if value.blank?
  end
end

# Traduire uniquement les champs manquants
if missing_translations.any?
  project.translate_with_mistral!(
    from: I18n.default_locale,
    to: missing_translations.map { |t| t[:locale] }.uniq,
    context: "projet de développement web"
  )
end
```

## Gestion des erreurs

```ruby
begin
  project.translate_with_mistral!(from: :fr, to: [:en])
rescue MistralTranslator::Client::AuthenticationError => e
  Rails.logger.error("Clé API invalide : #{e.message}")
  flash[:alert] = "Erreur d'authentification avec l'API Mistral"
rescue MistralTranslator::Client::RateLimitError => e
  Rails.logger.warn("Rate limit dépassé : #{e.message}")
  flash[:alert] = "Trop de requêtes, veuillez réessayer plus tard"
rescue MistralTranslator::Client::ApiError => e
  Rails.logger.error("Erreur API : #{e.message}")
  flash[:alert] = "Erreur lors de la traduction"
end
```

## Bonnes pratiques

1. **Utilisez les jobs asynchrones** pour les traductions en production
2. **Ajoutez un contexte** pour améliorer la qualité des traductions
3. **Utilisez un glossaire** pour préserver les termes techniques
4. **Vérifiez les traductions existantes** avant de traduire pour éviter les appels API inutiles
5. **Gérez les erreurs** avec des try/catch appropriés
6. **Respectez les rate limits** en utilisant les délais configurés


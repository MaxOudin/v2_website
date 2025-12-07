# Documentation - Service de Traduction Mistral

## Vue d'ensemble

Le service de traduction Mistral permet de traduire automatiquement les champs traduisibles de vos modèles Rails en utilisant l'API Mistral. Il supporte :

- **Champs Mobility** : string et text
- **Champs RichText** : ActionText (rich text)

## Documentation complémentaire

- **[Traduction dans le formulaire](./TRADUCTION_FORMULAIRE.md)** : Guide d'utilisation des boutons de traduction dans le formulaire de projet
- **[Exemples d'utilisation](./EXEMPLE_MISTRAL.md)** : Exemples de code pour utiliser le service

## Configuration

### Variables d'environnement

Définissez votre clé API Mistral dans votre fichier `.env` :

```bash
MISTRAL_API_KEY=votre_cle_api_ici
```

### Configuration personnalisée

Vous pouvez personnaliser la configuration dans `config/initializers/mistral_translator.rb` :

```ruby
MistralTranslator.configure do |config|
  config.api_key = "votre_cle" # Par défaut, lit depuis ENV["MISTRAL_API_KEY"]
  config.model = "mistral-small" # Modèle à utiliser
  config.default_temperature = 0.3 # Température pour la génération
  config.rate_limit_delay = 2 # Délai en secondes entre les requêtes
  config.retry_delays = [2, 4, 8, 16] # Délais de retry en cas d'erreur
end
```

## Utilisation

### Dans un modèle

Incluez le concern `MistralTranslatable` dans votre modèle :

```ruby
class Project < ApplicationRecord
  include Mobility
  include TranslatableRichText
  include MistralTranslatable

  translates :title, type: :string
  translates :description, type: :text
  has_rich_text :context
  has_translated_rich_text :context
end
```

### Méthodes disponibles

#### Traduire tous les champs

```ruby
project = Project.find(1)

# Traduire tous les champs traduisibles vers toutes les locales disponibles
results = project.translate_with_mistral!

# Traduire depuis le français vers l'anglais uniquement
results = project.translate_with_mistral!(
  from: :fr,
  to: [:en]
)

# Avec contexte et glossaire
results = project.translate_with_mistral!(
  from: :fr,
  to: [:en],
  context: "projet de développement web",
  glossary: { "Rails" => "Rails", "API" => "API" }
)
```

#### Traduire uniquement les champs Mobility

```ruby
# Tous les champs Mobility
project.translate_mobility_fields!(
  fields: [:title, :description],
  from: :fr,
  to: [:en]
)

# Un champ spécifique
project.translate_mobility_field!(
  field: :title,
  from: :fr,
  to: :en,
  context: "titre de projet"
)
```

#### Traduire uniquement les champs RichText

```ruby
# Tous les champs RichText
project.translate_rich_text_fields!(
  fields: [:context],
  from: :fr,
  to: [:en]
)

# Un champ spécifique
project.translate_rich_text_field!(
  field: :context,
  from: :fr,
  to: :en,
  context: "description de projet"
)
```

### Traduction asynchrone

Pour traduire de manière asynchrone (recommandé pour les gros volumes) :

```ruby
# Enqueue un job de traduction
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

### Utilisation directe du service

Si vous avez besoin de plus de contrôle :

```ruby
# Service principal
service = MistralTranslator::MistralTranslatorService.new

# Traduire un enregistrement
results = service.translate_record(
  project,
  from: :fr,
  to: [:en],
  context: "projet web",
  fields: [:title, :description, :context]
)

# Traduire un texte simple
translated = service.translate_text(
  "Bonjour le monde",
  from: "fr",
  to: "en",
  context: "salutation"
)
```

## Rake Tasks

### Traduire tous les projets

```bash
rake mistral_translator:translate_projects
```

### Traduire un projet spécifique

```bash
rake mistral_translator:translate_project[123]
```

### Tester la connexion API

```bash
rake mistral_translator:test_connection
```

## Exemples d'utilisation

### Exemple 1 : Traduction après création

```ruby
class ProjectsController < ApplicationController
  def create
    @project = Project.new(project_params)
    
    if @project.save
      # Traduire automatiquement après la création
      @project.translate_with_mistral!(
        from: I18n.default_locale,
        to: I18n.available_locales.reject { |l| l == I18n.default_locale }
      )
      
      redirect_to @project, notice: "Projet créé et traduit avec succès"
    else
      render :new
    end
  end
end
```

### Exemple 2 : Traduction asynchrone après création

```ruby
class ProjectsController < ApplicationController
  def create
    @project = Project.new(project_params)
    
    if @project.save
      # Traduire de manière asynchrone
      MistralTranslationJob.perform_later(
        "Project",
        @project.id,
        {
          from: I18n.default_locale,
          to: I18n.available_locales.reject { |l| l == I18n.default_locale }
        }
      )
      
      redirect_to @project, notice: "Projet créé, traduction en cours..."
    else
      render :new
    end
  end
end
```

### Exemple 3 : Traduction avec callback

```ruby
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

## Gestion des erreurs

Le service gère automatiquement :

- **Rate limiting** : Retry automatique avec délais exponentiels
- **Erreurs d'API** : Logging des erreurs sans faire planter l'application
- **Traductions existantes** : Ne traduit pas si la traduction existe déjà

### Exceptions

```ruby
begin
  project.translate_with_mistral!(from: :fr, to: [:en])
rescue MistralTranslator::Client::AuthenticationError => e
  # Clé API invalide
  Rails.logger.error("Erreur d'authentification : #{e.message}")
rescue MistralTranslator::Client::RateLimitError => e
  # Limite de taux dépassée
  Rails.logger.warn("Rate limit : #{e.message}")
rescue MistralTranslator::Client::ApiError => e
  # Autre erreur API
  Rails.logger.error("Erreur API : #{e.message}")
end
```

## Performance et optimisations

### Rate limiting

Le service inclut un délai par défaut de 2 secondes entre chaque requête pour éviter de dépasser les limites de l'API. Vous pouvez l'ajuster :

```ruby
MistralTranslator.configure do |config|
  config.rate_limit_delay = 1 # Réduire à 1 seconde (attention aux limites API)
end
```

### Traduction par batch

Pour traduire plusieurs enregistrements, utilisez les jobs asynchrones :

```ruby
Project.find_each do |project|
  MistralTranslationJob.perform_later("Project", project.id, { from: :fr, to: [:en] })
end
```

### Vérification des traductions existantes

Le service vérifie automatiquement si une traduction existe déjà avant de faire l'appel API, ce qui évite les appels inutiles.

## Structure des services

```
app/services/
├── mistral_translator/
│   ├── client.rb                    # Client API Mistral
│   ├── translation_service.rb       # Service de traduction de base
│   ├── mobility_translation_service.rb  # Service pour champs Mobility
│   └── rich_text_translation_service.rb # Service pour champs RichText
└── mistral_translator_service.rb    # Service principal orchestrateur
```

## Dépannage

### Erreur "MISTRAL_API_KEY n'est pas définie"

Vérifiez que la variable d'environnement est bien définie :

```bash
# Dans votre terminal
echo $MISTRAL_API_KEY

# Ou dans votre fichier .env
MISTRAL_API_KEY=votre_cle
```

### Les traductions ne se sauvegardent pas

Assurez-vous que :
1. L'enregistrement est bien sauvegardé (`save!` est appelé)
2. Les validations ne bloquent pas la sauvegarde
3. Les champs sont bien déclarés comme traduisibles

### Rate limit dépassé

Augmentez le `rate_limit_delay` dans la configuration ou utilisez les jobs asynchrones pour espacer les requêtes.

## Traduction depuis le formulaire

Le formulaire de projet inclut des boutons pour traduire directement depuis l'interface. Voir la [documentation complète](./TRADUCTION_FORMULAIRE.md) pour plus de détails.

### Utilisation rapide

1. Remplissez les champs en français (langue par défaut)
2. Cliquez sur le bouton "IA" à côté du champ dans la langue cible
3. La traduction apparaît automatiquement dans le champ

### Bouton de traduction globale

Le bouton "Traduire tout avec IA" en bas du formulaire traduit tous les champs d'un coup.

## Support

Pour toute question ou problème, consultez :
- La documentation de l'API Mistral : https://docs.mistral.ai
- Les logs Rails pour les erreurs détaillées
- La [documentation du formulaire](./TRADUCTION_FORMULAIRE.md) pour les problèmes d'interface


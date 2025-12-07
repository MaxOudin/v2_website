# Documentation du Système de Traduction

## Vue d'ensemble

L'application utilise un système de traduction hybride qui combine deux approches :

1. **Mobility** : Pour les champs simples (string, text) - stockés dans des tables dédiées
2. **TranslatableRichText** : Pour les champs ActionText (rich text) - stockés dans une table personnalisée avec association polymorphique

## Configuration I18n

### Locales disponibles

Les locales sont configurées dans `config/application.rb` :

```ruby
config.i18n.available_locales = [:fr, :en]
config.i18n.default_locale = :fr
config.i18n.fallbacks = { fr: :en, en: :fr }
```

- **Locales supportées** : Français (`:fr`) et Anglais (`:en`)
- **Locale par défaut** : Français
- **Fallbacks** : Si une traduction n'existe pas dans une locale, le système cherche automatiquement dans l'autre locale

### Gestion de la locale dans les routes

Les routes sont configurées pour accepter un paramètre de locale optionnel :

```ruby
scope "(:locale)", locale: /en|fr/ do
  # routes...
end
```

La locale est définie dans `ApplicationController` via le paramètre `:locale` ou utilise la locale par défaut.

## Architecture du Système

### 1. Mobility - Traduction des champs simples

**Gem utilisée** : `mobility` avec le backend `:key_value`

**Configuration** : `config/initializers/mobility.rb`

#### Plugins activés

- `backend :key_value` : Stockage des traductions dans des tables séparées
- `active_record` : Support ActiveRecord
- `reader` / `writer` : Méthodes de lecture/écriture
- `query` : Scope `i18n` pour interroger les traductions
- `cache` : Mise en cache des lectures/écritures
- `dirty` : Suivi des modifications (pour les validations)
- `fallbacks` : Utilise `I18n.fallbacks` pour les fallbacks
- `presence` : Convertit les chaînes vides en `nil`
- `locale_accessors` : Génère automatiquement les méthodes `field_name_locale` et `field_name_locale=`

#### Utilisation dans un modèle

```ruby
class Project < ApplicationRecord
  include Mobility
  
  # Pour un champ string
  translates :title, type: :string
  
  # Pour un champ text
  translates :description, type: :text
end
```

#### Méthodes disponibles

Après avoir déclaré `translates :title`, vous avez accès à :

- `project.title` : Retourne la valeur dans la locale courante (`I18n.locale`)
- `project.title = "Valeur"` : Définit la valeur dans la locale courante
- `project.title_fr` : Accès direct à la version française
- `project.title_fr = "Titre"` : Définit la version française
- `project.title_en` : Accès direct à la version anglaise
- `project.title_en = "Title"` : Définit la version anglaise

#### Structure de la base de données

Les traductions sont stockées dans deux tables :

**`mobility_string_translations`** (pour les champs `type: :string`) :
- `locale` : La locale (fr, en)
- `key` : Le nom du champ (title, description, etc.)
- `value` : La valeur traduite
- `translatable_type` : Le type du modèle (Project, etc.)
- `translatable_id` : L'ID de l'enregistrement

**`mobility_text_translations`** (pour les champs `type: :text`) :
- Même structure que `mobility_string_translations` mais avec `value` en type `text`

### 2. TranslatableRichText - Traduction des champs ActionText

**Module personnalisé** : `app/models/concerns/translatable_rich_text.rb`

Ce module gère les traductions pour les champs ActionText (rich text) qui nécessitent une gestion spéciale car ActionText stocke le contenu dans des tables séparées.

#### Fonctionnement

1. **Initialisation** : Un hash `@pending_translations` est initialisé après l'initialisation de l'objet
2. **Stockage temporaire** : Les traductions sont stockées temporairement dans `@pending_translations` avant la sauvegarde
3. **Sauvegarde différée** : Après la sauvegarde du modèle principal, un callback `after_save` sauvegarde les traductions dans la table `translated_rich_texts`

#### Utilisation dans un modèle

```ruby
class Project < ApplicationRecord
  include TranslatableRichText
  
  # Déclaration standard ActionText
  has_rich_text :context
  
  # Déclaration de la traduction
  has_translated_rich_text :context
end
```

#### Méthodes disponibles

Après avoir déclaré `has_translated_rich_text :context`, vous avez accès à :

- `project.context` : Retourne le contenu dans la locale courante
- `project.context = content` : Définit le contenu dans la locale courante
- `project.context_fr` : Accès direct à la version française
- `project.context_fr = content` : Définit la version française
- `project.context_en` : Accès direct à la version anglaise
- `project.context_en = content` : Définit la version anglaise

#### Gestion des fallbacks

Le module implémente une logique de fallback personnalisée :

1. Vérifie d'abord les traductions en attente (`@pending_translations`)
2. Si non trouvé, cherche dans la base de données pour la locale demandée
3. Si non trouvé et que des fallbacks sont configurés, cherche dans les locales de fallback

#### Structure de la base de données

**`translated_rich_texts`** :
- `locale` : La locale (fr, en)
- `field_name` : Le nom du champ (context, etc.)
- `record_type` : Le type du modèle (Project, etc.)
- `record_id` : L'ID de l'enregistrement
- `body` : Le contenu ActionText (via `has_rich_text :body`)

**Contrainte d'unicité** : Un index unique garantit qu'il ne peut y avoir qu'une seule traduction par combinaison `(record_type, record_id, field_name, locale)`

**Association ActionText** : Le champ `body` est un champ ActionText, stocké dans les tables standard d'ActionText (`action_text_rich_texts`)

## Exemple d'utilisation complète

### Modèle Project

```ruby
class Project < ApplicationRecord
  include Mobility
  include TranslatableRichText
  
  # Champs simples traduits avec Mobility
  translates :title, type: :string
  translates :description, type: :text
  
  # Champ rich text traduit avec TranslatableRichText
  has_rich_text :context
  has_translated_rich_text :context
end
```

### Contrôleur

Dans le contrôleur, les paramètres doivent inclure les traductions pour chaque locale :

```ruby
def project_params
  params.require(:project).permit(
    *I18n.available_locales.map { |locale| "title_#{locale}" },
    *I18n.available_locales.map { |locale| "description_#{locale}" },
    *I18n.available_locales.map { |locale| "context_#{locale}" },
    # autres paramètres...
  )
end
```

### Formulaire

Dans les vues, vous pouvez créer des champs pour chaque locale :

```erb
<% I18n.available_locales.each do |locale| %>
  <div class="locale-fields" data-locale="<%= locale %>">
    <%= form.label "title_#{locale}" %>
    <%= form.text_field "title_#{locale}" %>
    
    <%= form.label "description_#{locale}" %>
    <%= form.text_area "description_#{locale}" %>
    
    <%= form.label "context_#{locale}" %>
    <%= form.rich_text_area "context_#{locale}" %>
  </div>
<% end %>
```

### Utilisation dans le code

```ruby
# Création avec traductions
project = Project.new
project.title_fr = "Mon Projet"
project.title_en = "My Project"
project.context_fr = "<p>Description en français</p>"
project.context_en = "<p>Description in English</p>"
project.save

# Lecture selon la locale courante
I18n.locale = :fr
project.title # => "Mon Projet"
project.context # => "<p>Description en français</p>"

I18n.locale = :en
project.title # => "My Project"
project.context # => "<p>Description in English</p>"

# Accès direct à une locale spécifique
project.title_fr # => "Mon Projet"
project.context_en # => "<p>Description in English</p>"

# Fallback automatique
I18n.locale = :fr
# Si title_fr n'existe pas, cherche title_en automatiquement
```

## Différences entre Mobility et TranslatableRichText

| Aspect | Mobility | TranslatableRichText |
|--------|----------|---------------------|
| **Type de champs** | String, Text | ActionText (Rich Text) |
| **Stockage** | Tables Mobility (`mobility_string_translations`, `mobility_text_translations`) | Table personnalisée (`translated_rich_texts`) + ActionText |
| **Sauvegarde** | Immédiate | Différée (via `after_save` callback) |
| **Fallbacks** | Géré par Mobility via `I18n.fallbacks` | Implémentation personnalisée dans le module |
| **Cache** | Activé par défaut | Pas de cache explicite |
| **Dirty tracking** | Activé par défaut | Non disponible |

## Points importants

### 1. Ordre de sauvegarde

Pour `TranslatableRichText`, les traductions sont sauvegardées **après** la sauvegarde du modèle principal. Cela garantit que l'enregistrement principal existe avant de créer les associations.

### 2. Traductions en attente

Le système utilise un mécanisme de "traductions en attente" (`@pending_translations`) pour les champs rich text. Cela permet de :
- Collecter toutes les traductions avant la sauvegarde
- Éviter des requêtes multiples à la base de données
- Gérer correctement les associations polymorphiques

### 3. Validations

Les validations peuvent être conditionnelles selon la locale :

```ruby
validates :title, presence: true, if: -> { I18n.locale == I18n.default_locale }
```

### 4. Requêtes avec Mobility

Mobility fournit un scope `i18n` pour interroger les traductions :

```ruby
# Rechercher des projets avec un titre spécifique dans la locale courante
Project.i18n.where(title: "Mon Projet")

# Rechercher dans une locale spécifique
Project.i18n { title }.where(title: "My Project")
```

## Migration et évolution

### Ajouter une nouvelle locale

1. Mettre à jour `config/application.rb` :
   ```ruby
   config.i18n.available_locales = [:fr, :en, :es]
   config.i18n.fallbacks = { fr: [:en, :es], en: [:fr, :es], es: [:en, :fr] }
   ```

2. Les méthodes d'accès seront automatiquement générées pour la nouvelle locale

3. Mettre à jour les routes si nécessaire :
   ```ruby
   scope "(:locale)", locale: /en|fr|es/ do
   ```

### Ajouter un nouveau champ traduit

1. **Pour un champ simple** :
   ```ruby
   translates :new_field, type: :string
   ```

2. **Pour un champ rich text** :
   ```ruby
   has_rich_text :new_field
   has_translated_rich_text :new_field
   ```

3. Mettre à jour les paramètres du contrôleur :
   ```ruby
   *I18n.available_locales.map { |locale| "new_field_#{locale}" }
   ```

## Dépannage

### Les traductions ne se sauvegardent pas

- Vérifier que le modèle principal est bien sauvegardé (pour `TranslatableRichText`)
- Vérifier les validations qui pourraient empêcher la sauvegarde
- Vérifier les logs pour les erreurs de base de données

### Les fallbacks ne fonctionnent pas

- Vérifier la configuration `I18n.fallbacks` dans `config/application.rb`
- Vérifier que les traductions existent dans les locales de fallback

### Erreurs de contrainte d'unicité

- Vérifier qu'il n'y a pas de doublons dans `translated_rich_texts`
- Vérifier l'index unique : `index_translated_rich_texts_uniqueness`

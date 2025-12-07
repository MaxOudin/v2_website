# Documentation de la Configuration Build : Rails, Bun, JSBuild et Tailwind

## Vue d'ensemble

L'application utilise une architecture moderne pour la gestion des assets :

- **Rails 7.1** avec **Propshaft** (asset pipeline moderne)
- **Bun** comme runtime et builder JavaScript (alternative à Node.js)
- **JSBundling-Rails** pour l'intégration du build JavaScript
- **Tailwind CSS** pour le styling avec **tailwindcss-rails**
- **Foreman** pour orchestrer les processus de développement

## Architecture des Assets

### Stack Technique

```
┌─────────────────────────────────────────────────────────┐
│                    Rails Application                     │
├─────────────────────────────────────────────────────────┤
│  Propshaft (Asset Pipeline)                              │
│  ├── JavaScript: Bun Build → app/assets/builds/         │
│  ├── CSS: Tailwind CLI → app/assets/builds/              │
│  └── Images: app/assets/images/                          │
└─────────────────────────────────────────────────────────┘
```

### Composants Principaux

1. **Propshaft** : Pipeline d'assets moderne et simple (remplace Sprockets)
2. **Bun** : Runtime JavaScript ultra-rapide avec builder intégré
3. **JSBundling-Rails** : Bridge entre Rails et les outils de build JS modernes
4. **Tailwind CSS** : Framework CSS utility-first
5. **Foreman** : Gestionnaire de processus pour le développement

## Configuration JavaScript avec Bun

### Installation et Configuration

#### 1. Gems Rails

Dans le `Gemfile` :

```ruby
# Pipeline d'assets moderne
gem "propshaft"

# Intégration des outils de build JavaScript
gem "jsbundling-rails"
gem "cssbundling-rails"

# Hotwire pour les interactions
gem "turbo-rails"
gem "stimulus-rails"
```

#### 2. Configuration Bun

**Fichier : `bun.config.js`**

```javascript
import path from 'path';
import fs from 'fs';

const config = {
  sourcemap: "external",  // Génère des sourcemaps externes
  entrypoints: ["app/javascript/application.js"],  // Point d'entrée
  outdir: path.join(process.cwd(), "app/assets/builds"),  // Dossier de sortie
};

const build = async (config) => {
  const result = await Bun.build(config);

  if (!result.success) {
    if (process.argv.includes('--watch')) {
      console.error("Build failed");
      for (const message of result.logs) {
        console.error(message);
      }
      return;
    } else {
      throw new AggregateError(result.logs, "Build failed");
    }
  }
};

(async () => {
  await build(config);

  if (process.argv.includes('--watch')) {
    // Mode watch : surveille les changements dans app/javascript
    fs.watch(path.join(process.cwd(), "app/javascript"), { recursive: true }, (eventType, filename) => {
      console.log(`File changed: ${filename}. Rebuilding...`);
      build(config);
    });
  } else {
    process.exit(0);
  }
})();
```

**Points clés :**
- Utilise l'API native de Bun pour le build
- Génère des sourcemaps externes pour le debugging
- Support du mode watch pour le développement
- Surveille récursivement tous les fichiers dans `app/javascript`

#### 3. Point d'entrée JavaScript

**Fichier : `app/javascript/application.js`**

```javascript
import "@hotwired/turbo-rails"
import "trix"
import "@rails/actiontext"

import "./controllers"
```

**Structure :**
- Importe Turbo Rails pour la navigation SPA-like
- Importe Trix et ActionText pour l'édition de texte riche
- Importe les contrôleurs Stimulus

#### 4. Contrôleurs Stimulus

**Fichier : `app/javascript/controllers/index.js`**

```javascript
// Import and register all your controllers
import { application } from "./application"

import HelloController from "./hello_controller"
application.register("hello", HelloController)
```

**Structure :**
- Auto-enregistrement des contrôleurs Stimulus
- Chaque contrôleur est importé et enregistré manuellement

#### 5. Scripts NPM/Bun

**Fichier : `package.json`**

```json
{
  "scripts": {
    "build": "bun bun.config.js",
    "build:css": "tailwindcss -i ./app/assets/stylesheets/application.css -o ./app/assets/builds/application.css --minify"
  }
}
```

**Commandes disponibles :**
- `bun run build` : Build unique du JavaScript
- `bun run build --watch` : Build en mode watch
- `bun run build:css` : Build du CSS Tailwind (production, minifié)

### Flux de Build JavaScript

```
app/javascript/application.js
    ↓
Bun.build() (via bun.config.js)
    ↓
app/assets/builds/application.js
    ↓
Propshaft (serve les assets)
    ↓
Layout (stylesheet_link_tag / javascript_include_tag)
```

## Configuration Tailwind CSS

### Installation et Configuration

#### 1. Gems Rails

Dans le `Gemfile` :

```ruby
gem "tailwindcss-ruby", "~> 4.1"
gem "tailwindcss-rails", "~> 4.3"
```

Ces gems fournissent :
- L'exécutable Tailwind CLI
- Les commandes Rails pour Tailwind
- L'intégration avec le pipeline d'assets

#### 2. Dépendances NPM

Dans le `package.json` :

```json
{
  "dependencies": {
    "@tailwindcss/forms": "^0.5.7",
    "@tailwindcss/typography": "^0.5.10",
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.38",
    "tailwindcss": "^3.4.1"
  }
}
```

**Plugins Tailwind :**
- `@tailwindcss/forms` : Styles pour les formulaires
- `@tailwindcss/typography` : Styles typographiques pour le contenu riche

#### 3. Fichier CSS Principal

**Fichier : `app/assets/stylesheets/application.css`**

```css
/* Directives Tailwind */
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Composants personnalisés */
@layer components {
  .btn-primary {
    @apply px-4 py-2 bg-indigo-600 text-white font-semibold rounded-lg shadow-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:ring-opacity-75;
  }
}

/* Utilitaires personnalisés */
@layer utilities {
  @keyframes fade-in-up {
    from {
      opacity: 0;
      transform: translateY(20px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .animate-fade-in-up {
    animation: fade-in-up 0.6s ease-out;
  }
  
  /* ... autres animations et utilitaires ... */
}
```

**Structure :**
- Directives Tailwind standard (`@tailwind base/components/utilities`)
- Composants personnalisés dans `@layer components`
- Utilitaires personnalisés dans `@layer utilities`

#### 4. Fichier Tailwind Rails

**Fichier : `app/assets/tailwind/application.css`**

```css
@import "tailwindcss";
```

Ce fichier est utilisé par la gem `tailwindcss-rails` pour générer le CSS compilé.

#### 5. Configuration Rails pour Tailwind

La gem `tailwindcss-rails` fournit des commandes Rake :

- `rails tailwindcss:install` : Installation initiale
- `rails tailwindcss:watch` : Mode watch pour le développement
- `rails tailwindcss:build` : Build de production

### Flux de Build CSS

```
app/assets/stylesheets/application.css
    ↓
Tailwind CLI (via tailwindcss-rails)
    ↓
app/assets/builds/tailwind.css (ou application.css)
    ↓
Propshaft (serve les assets)
    ↓
Layout (stylesheet_link_tag "tailwind")
```

## Configuration Propshaft

### Initialisation

**Fichier : `config/initializers/assets.rb`**

```ruby
# Version des assets (pour invalider le cache)
Rails.application.config.assets.version = "1.0"

# Ajouter node_modules au chemin de recherche
Rails.application.config.assets.paths << Rails.root.join("node_modules")

# Assets à précompiler
Rails.application.config.assets.precompile += %w( trix.css actiontext.css )
```

**Points importants :**
- Propshaft sert automatiquement les fichiers dans `app/assets`
- Les fichiers compilés dans `app/assets/builds` sont servis directement
- Pas besoin de précompilation complexe comme avec Sprockets
- **Important** : Propshaft ne supporte **PAS** les directives `*= require` (spécifique à Sprockets)

### Chargement des CSS externes (Trix, ActionText)

**⚠️ Différence importante avec Sprockets :**

Avec **Sprockets**, vous pouvez utiliser :
```css
*= require trix
*= require actiontext
```

Avec **Propshaft**, ces directives ne fonctionnent pas. Il faut charger les CSS directement dans le layout :

**Fichier : `app/views/layouts/application.html.erb`**

```erb
<%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
<%= stylesheet_link_tag "trix/dist/trix", "data-turbo-track": "reload" %>
<%= stylesheet_link_tag "actiontext", "data-turbo-track": "reload" %>
<%= stylesheet_link_tag "application", "data-turbo-track": Rails.env.production? ? "reload" : "" %>
```

**Pourquoi cette approche ?**
- Propshaft sert directement les fichiers depuis `node_modules` (grâce à `config.assets.paths`)
- Le CSS de Trix contient les icônes SVG encodées en data URI
- Charger directement dans le layout garantit que les styles sont appliqués dans le bon ordre

**Note sur les icônes Trix :**
- Les icônes SVG sont incluses directement dans `trix/dist/trix.css` sous forme de data URI
- Aucun fichier SVG séparé n'est nécessaire
- Si les icônes ne s'affichent pas, vérifier que le CSS de Trix est bien chargé dans le layout

## Intégration dans les Vues

### Layout Principal

**Fichier : `app/views/layouts/application.html.erb`**

```erb
<head>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  
  <!-- CSS Tailwind compilé -->
  <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
  
  <!-- CSS Trix (éditeur rich text) - IMPORTANT avec Propshaft -->
  <%= stylesheet_link_tag "trix/dist/trix", "data-turbo-track": "reload" %>
  
  <!-- CSS ActionText pour l'éditeur -->
  <%= stylesheet_link_tag "actiontext", "data-turbo-track": "reload" %>
  
  <!-- CSS application (styles personnalisés) -->
  <%= stylesheet_link_tag "application", "data-turbo-track": Rails.env.production? ? "reload" : "" %>
  
  <!-- JavaScript compilé -->
  <%= javascript_include_tag "application", "data-turbo-track": "reload", type: "module" %>
</head>
```

**Points clés :**
- `data-turbo-track: "reload"` : Force le rechargement des assets lors des changements
- `type: "module"` : Indique que le JavaScript utilise les modules ES6
- **Ordre d'inclusion important** : Tailwind → Trix → ActionText → Application → JavaScript
- Le CSS de Trix doit être chargé **avant** ActionText pour que les styles personnalisés d'ActionText puissent surcharger ceux de Trix
- En développement, le CSS application n'utilise pas `data-turbo-track` pour permettre à hotwire-livereload de gérer le rechargement

## Processus de Développement

### Procfile.dev

**Fichier : `Procfile.dev`**

```
web: bin/rails server
css: bin/rails tailwindcss:watch
js: bun run build --watch
```

**Processus lancés :**
1. **web** : Serveur Rails (port 3000 par défaut)
2. **css** : Watch Tailwind (recompile automatiquement le CSS)
3. **js** : Watch Bun (recompile automatiquement le JavaScript)

### Script bin/dev

**Fichier : `bin/dev`**

```bash
#!/usr/bin/env sh

# Installe foreman si nécessaire
if gem list --no-installed --exact --silent foreman; then
  echo "Installing foreman..."
  gem install foreman
fi

# Port par défaut
export PORT="${PORT:-3000}"

# Lance tous les processus du Procfile.dev
exec foreman start -f Procfile.dev --env /dev/null "$@"
```

**Utilisation :**
```bash
bin/dev
```

Cela lance automatiquement :
- Le serveur Rails
- Le watcher Tailwind
- Le watcher Bun

## Structure des Dossiers

```
app/
├── assets/
│   ├── builds/              # Fichiers compilés (générés)
│   │   ├── application.js   # JavaScript compilé par Bun
│   │   └── tailwind.css     # CSS compilé par Tailwind
│   ├── images/              # Images statiques
│   ├── stylesheets/         # Sources CSS
│   │   ├── application.css  # CSS principal avec directives Tailwind (sans *= require)
│   │   └── actiontext.css   # Styles personnalisés pour ActionText/Trix
│   └── tailwind/
│       └── application.css  # Fichier utilisé par tailwindcss-rails
└── javascript/
    ├── application.js       # Point d'entrée JavaScript (importe trix et @rails/actiontext)
    └── controllers/         # Contrôleurs Stimulus
        ├── application.js
        ├── index.js
        └── hello_controller.js

# Note : Le CSS de Trix est chargé directement depuis node_modules/trix/dist/trix.css
# via stylesheet_link_tag dans le layout (Propshaft ne supporte pas *= require)
```

## Commandes Importantes

### Développement

```bash
# Lancer tous les processus (Rails + Tailwind watch + Bun watch)
bin/dev

# Ou individuellement :
bin/rails server              # Serveur Rails uniquement
bin/rails tailwindcss:watch   # Watch Tailwind uniquement
bun run build --watch         # Watch Bun uniquement
```

### Build de Production

```bash
# Build JavaScript
bun run build

# Build CSS (minifié)
bun run build:css

# Ou via Rails
bin/rails assets:precompile
```

### Installation

```bash
# Installer les dépendances Ruby
bundle install

# Installer les dépendances JavaScript (via Bun)
bun install

# Installer Tailwind (si nécessaire)
bin/rails tailwindcss:install
```

## Configuration des Environnements

### Développement

**Fichier : `config/environments/development.rb`**

```ruby
# Assets non compilés en développement
config.assets.compile = true
config.assets.quiet = true  # Supprime les logs d'assets
```

**Comportement :**
- Les assets sont servis directement depuis `app/assets/builds`
- Les watchers recompilent automatiquement lors des changements
- Pas de minification (pour faciliter le debugging)

### Production

**Fichier : `config/environments/production.rb`**

```ruby
# Ne pas compiler les assets à la volée
config.assets.compile = false

# Les assets doivent être précompilés
# Utiliser: bin/rails assets:precompile
```

**Comportement :**
- Les assets doivent être précompilés avant le déploiement
- Minification activée pour le CSS (via `--minify`)
- Sourcemaps externes pour le JavaScript

## Points Importants de la Configuration

### 1. Bun vs Node.js

**Pourquoi Bun ?**
- **Performance** : Bun est significativement plus rapide que Node.js
- **Build intégré** : Pas besoin d'esbuild séparé (même si esbuild est dans package.json, il n'est pas utilisé)
- **Compatibilité** : Compatible avec npm et les packages Node.js standards

**Note** : Bien qu'`esbuild` soit dans les dépendances, le projet utilise directement l'API de build de Bun via `bun.config.js`.

### 2. Propshaft vs Sprockets

**Avantages de Propshaft :**
- Plus simple et plus léger
- Pas de compilation complexe
- Les fichiers sont servis directement
- Meilleure intégration avec les outils de build modernes

**Différences importantes :**
- ❌ **Ne supporte PAS** les directives `*= require` (spécifique à Sprockets)
- ✅ **Utilise** `stylesheet_link_tag` directement dans les layouts pour charger les CSS externes
- ✅ **Sert directement** les fichiers depuis `node_modules` si configuré dans `config.assets.paths`
- ✅ **Plus simple** : pas de manifest complexe, pas de précompilation nécessaire en développement

### 3. Tailwind via Gem vs NPM

**Approche hybride :**
- La gem `tailwindcss-rails` fournit les commandes Rails
- Le package NPM `tailwindcss` fournit le CLI et les plugins
- Les deux travaillent ensemble pour une intégration optimale

### 4. Sourcemaps

**Configuration :**
- JavaScript : Sourcemaps externes (`sourcemap: "external"`)
- CSS : Sourcemaps générées par Tailwind CLI (si activées)

**Utilité :**
- Permet le debugging dans les outils de développement
- Mappe le code compilé vers le code source

### 5. Hot Reload avec Turbo Drive

**Turbo Drive :**
- `data-turbo-track: "reload"` force le rechargement des assets
- Lorsqu'un asset change, Turbo recharge automatiquement la page
- Pas besoin de rechargement manuel dans la plupart des cas

### 6. Hotwire LiveReload

**Configuration de hotwire-livereload :**

La gem `hotwire-livereload` permet de recharger automatiquement la page du navigateur lors de changements dans les fichiers de l'application, sans intervention manuelle.

#### Installation

**Dans le `Gemfile` :**

```ruby
group :development do
  gem "hotwire-livereload"
end
```

#### Configuration Action Cable

**Fichier : `config/cable.yml`**

```yaml
development:
  adapter: async  # Utilise l'adaptateur async (pas besoin de Redis)
```

L'adaptateur `async` fonctionne en développement sans nécessiter Redis. Pour la production, utilisez l'adaptateur `redis`.

#### Intégration dans le Layout (Optionnel)

Si vous souhaitez utiliser Action Cable pour le live reload, ajoutez les tags suivants dans le layout :

**Fichier : `app/views/layouts/application.html.erb`**

```erb
<head>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= action_cable_meta_tag %>
  <%= hotwire_livereload_tags if Rails.env.development? %>
  <!-- ... reste du head ... -->
</head>
```

**Note :** Par défaut, `hotwire-livereload` fonctionne sans configuration supplémentaire. Les tags ci-dessus sont optionnels et nécessaires uniquement si vous utilisez Action Cable pour le rechargement.

#### Répertoires Surveillés

Par défaut, `hotwire-livereload` surveille automatiquement :

- `app/views/` - Vues ERB
- `app/helpers/` - Helpers Rails
- `app/javascript/` - Fichiers JavaScript
- `app/assets/stylesheets/` - Fichiers CSS
- `app/assets/javascripts/` - Fichiers JavaScript (si utilisés)
- `app/assets/images/` - Images
- `app/components/` - Composants ViewComponent
- `config/locales/` - Fichiers de traduction
- `app/assets/builds/` - Fichiers compilés (si `jsbundling-rails` ou `cssbundling-rails` sont utilisés)

#### Configuration Avancée

**Fichier : `config/environments/development.rb`**

```ruby
Rails.application.configure do
  # Ajouter des répertoires personnalisés à surveiller
  config.hotwire_livereload.listen_paths << Rails.root.join('app/custom_folder')
  
  # Désactiver les répertoires par défaut et spécifier uniquement ceux souhaités
  # config.hotwire_livereload.disable_default_listeners = true
  # config.hotwire_livereload.listen_paths = [
  #   Rails.root.join('app/assets/stylesheets'),
  #   Rails.root.join('app/javascript')
  # ]
  
  # Forcer un rechargement complet de la page pour certains fichiers
  # config.hotwire_livereload.force_reload_paths << Rails.root.join('app/assets/stylesheets')
  
  # Utiliser Turbo Streams au lieu d'Action Cable (par défaut)
  # config.hotwire_livereload.reload_method = :turbo_stream
  
  # Activer le polling si les événements de fichiers ne fonctionnent pas
  # config.hotwire_livereload.listen_options[:force_polling] = true
end
```

#### Commandes Utiles

```bash
# Désactiver temporairement le live reload
bin/rails livereload:disable

# Réactiver le live reload
bin/rails livereload:enable
```

Ces commandes créent/suppriment un fichier `tmp/livereload-disabled.txt` pour contrôler le live reload sans redémarrer le serveur.

#### Fonctionnement

1. **Surveillance des fichiers** : `hotwire-livereload` surveille les changements dans les répertoires configurés
2. **Détection de changement** : Lorsqu'un fichier est modifié, la gem détecte le changement
3. **Rechargement automatique** : La page du navigateur se recharge automatiquement via WebSocket (Action Cable) ou Turbo Streams
4. **Pas de redémarrage serveur** : Le serveur Rails n'a pas besoin d'être redémarré pour la plupart des changements

#### Avantages

- ✅ Rechargement automatique de la page lors des changements
- ✅ Fonctionne avec le rechargement automatique du code Rails (`config.enable_reloading = true`)
- ✅ Compatible avec les watchers CSS et JavaScript existants
- ✅ Pas besoin de Redis en développement (utilise l'adaptateur `async`)
- ✅ Configuration minimale requise

#### Notes Importantes

- Le live reload fonctionne uniquement en environnement de développement
- Les changements dans `config/`, `routes.rb`, ou les initializers nécessitent toujours un redémarrage manuel du serveur
- Le rechargement automatique du code Rails (controllers, models, views) fonctionne indépendamment du live reload

## Configuration ActionText et Trix

### Installation

ActionText et Trix sont utilisés pour l'édition de texte riche dans l'application.

**Dépendances NPM :**
```json
{
  "dependencies": {
    "trix": "^2.0.10",
    "@rails/actiontext": "^7.1.5"
  }
}
```

**Import JavaScript :**
```javascript
// app/javascript/application.js
import "trix"
import "@rails/actiontext"
```

### Chargement du CSS avec Propshaft

**⚠️ Important :** Avec Propshaft, le CSS de Trix doit être chargé directement dans le layout, pas via `*= require` dans le CSS.

**Fichier : `app/views/layouts/application.html.erb`**
```erb
<%= stylesheet_link_tag "trix/dist/trix", "data-turbo-track": "reload" %>
<%= stylesheet_link_tag "actiontext", "data-turbo-track": "reload" %>
```

**Fichier : `app/assets/stylesheets/application.css`**
```css
/* ❌ NE PAS UTILISER avec Propshaft */
/* *= require trix */
/* *= require actiontext */

/* ✅ Utiliser les directives Tailwind directement */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

### Styles personnalisés pour Trix

**Fichier : `app/assets/stylesheets/actiontext.css`**

```css
/* Styles personnalisés pour l'éditeur Trix */
trix-editor {
  @apply block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm;
  min-height: 25em;
  max-height: 50em;
  overflow-y: auto;
  padding: 1rem;
  line-height: 1.5;
}

.trix-button-group {
  @apply border border-gray-300 rounded-md overflow-hidden;
}

/* ⚠️ Important : préserver les background-image (icônes SVG) */
.trix-button {
  @apply border-r border-gray-300 hover:bg-gray-50;
  padding: 0.5rem;
  /* Ne pas écraser les background-image qui contiennent les icônes SVG */
}
```

**Points importants :**
- Les icônes SVG sont incluses dans le CSS de Trix sous forme de data URI
- Ne pas utiliser `@apply` sur les propriétés qui écraseraient les `background-image`
- Les styles personnalisés doivent être chargés **après** le CSS de Trix dans le layout

### Problèmes courants

**Les icônes ne s'affichent pas :**
1. Vérifier que `trix/dist/trix.css` est bien chargé dans le layout
2. Vérifier l'ordre de chargement : Trix → ActionText → Application
3. Vérifier que les styles personnalisés ne masquent pas les `background-image`
4. Vider le cache du navigateur (Ctrl+Shift+R ou Cmd+Shift+R)

**Le texte s'affiche au lieu des icônes :**
- Cela indique que le CSS de Trix n'est pas chargé
- Vérifier la console du navigateur pour les erreurs 404 sur `trix/dist/trix.css`
- Vérifier que `node_modules` est dans `config.assets.paths`

## Dépannage

### Les assets ne se rechargent pas

1. Vérifier que les watchers sont actifs :
   ```bash
   # Vérifier les processus
   ps aux | grep -E "(tailwind|bun|rails)"
   ```

2. Vérifier que les fichiers sont bien générés :
   ```bash
   ls -la app/assets/builds/
   ```

3. Vider le cache du navigateur (Ctrl+Shift+R ou Cmd+Shift+R)

### Erreurs de build

**JavaScript :**
```bash
# Vérifier les logs de Bun
bun run build

# Vérifier la syntaxe
bun check app/javascript/application.js
```

**CSS :**
```bash
# Vérifier la syntaxe Tailwind
bin/rails tailwindcss:build

# Vérifier les imports
cat app/assets/stylesheets/application.css
```

### Assets manquants en production

1. Précompiler les assets :
   ```bash
   bin/rails assets:precompile
   ```

2. Vérifier que les fichiers sont dans `app/assets/builds/`

3. Vérifier les permissions des fichiers

### Bun non trouvé

```bash
# Installer Bun
curl -fsSL https://bun.sh/install | bash

# Vérifier l'installation
bun --version
```

## Évolution et Maintenance

### Ajouter une nouvelle dépendance JavaScript

1. Installer avec Bun :
   ```bash
   bun add nom-du-package
   ```

2. Importer dans `app/javascript/application.js` ou dans un contrôleur

3. Rebuild :
   ```bash
   bun run build
   ```

### Ajouter un plugin Tailwind

1. Installer le package :
   ```bash
   bun add @tailwindcss/nom-plugin
   ```

2. Configurer dans `tailwind.config.js` (si le fichier existe) ou via les directives CSS

### Changer de builder JavaScript

Si vous souhaitez passer à esbuild ou webpack :

1. Modifier `bun.config.js` pour utiliser le nouveau builder
2. Mettre à jour les scripts dans `package.json`
3. Mettre à jour `Procfile.dev`

**Note** : L'approche actuelle avec Bun est optimale pour la performance et la simplicité.

## Résumé des Étapes de Configuration

1. ✅ **Installer les gems** : `jsbundling-rails`, `cssbundling-rails`, `tailwindcss-rails`, `propshaft`, `hotwire-livereload`
2. ✅ **Installer Bun** : Runtime JavaScript
3. ✅ **Créer `bun.config.js`** : Configuration du build JavaScript
4. ✅ **Créer `app/javascript/application.js`** : Point d'entrée
5. ✅ **Configurer Tailwind** : Fichiers CSS avec directives `@tailwind`
6. ✅ **Configurer Action Cable** : Adaptateur `async` pour le développement
7. ✅ **Configurer `Procfile.dev`** : Processus de développement
8. ✅ **Configurer le layout** : Inclusion des assets compilés
9. ✅ **Tester** : Lancer `bin/dev` et vérifier que tout fonctionne

Cette configuration offre un workflow moderne, performant et maintenable pour le développement Rails avec des outils JavaScript et CSS modernes, incluant le rechargement automatique de la page du navigateur.

# Traduction IA dans le Formulaire de Projet

## Vue d'ensemble

Le formulaire de projet inclut des boutons pour traduire automatiquement les champs avec l'IA Mistral directement depuis l'interface, sans quitter la page.

## Fonctionnalités

### Bouton de traduction globale

Un bouton "Traduire tout avec IA" est disponible en bas du formulaire pour traduire tous les champs traduisibles d'un coup. Ce bouton apparaît :
- **Uniquement si le projet est déjà sauvegardé** (persisted)
- **En bas du formulaire**, à gauche des boutons "Annuler" et "Enregistrer"

## Utilisation

### Traduire tous les champs

1. Remplissez tous les champs dans la langue par défaut (français)
2. Cliquez sur "Traduire tout avec IA" en bas du formulaire
3. Tous les champs traduisibles (title, description, context) seront traduits vers les autres langues disponibles
4. La page se recharge automatiquement après la traduction pour afficher les résultats

**Note** : Seuls les champs vides seront traduits. Si une traduction existe déjà, elle sera conservée.

## Architecture technique

### Structure du bouton

Le bouton utilise Stimulus pour gérer les interactions :

```erb
<%= button_tag type: :button, 
    data: { 
      action: "click->mistral-translator#translateAll",
      from: I18n.default_locale,
      url: translate_all_project_path(project),
      confirm: "Voulez-vous traduire tous les champs ?"
    } do %>
  Traduire tout avec IA
<% end %>
```

### Contrôleur Stimulus

Le contrôleur `mistral-translator` gère :
- Les requêtes AJAX vers les actions de traduction
- La mise à jour automatique des champs après traduction
- Les notifications de succès/erreur
- Le rechargement de la page après traduction globale

**Fichier** : `app/javascript/controllers/mistral_translator_controller.js`

### Actions du contrôleur Rails

#### `translate_all`

Traduit tous les champs traduisibles d'un projet.

**Route** : `POST /projects/:id/translate_all`

**Paramètres** :
- `from` : langue source (défaut: locale par défaut)
- `to` : langues cibles (défaut: toutes les langues sauf la source)

**Réponse JSON** :
```json
{
  "success": true,
  "translated_count": 3,
  "results": {
    "mobility": [{"field": "title", "locale": "en"}],
    "rich_text": [{"field": "context", "locale": "en"}]
  }
}
```

## Gestion des erreurs

### Erreurs côté client

En cas d'erreur, une notification rouge s'affiche en haut à droite de l'écran pendant 3 secondes.

### Erreurs côté serveur

Les erreurs sont loggées dans les logs Rails et retournées dans la réponse JSON :

```json
{
  "success": false,
  "error": "Message d'erreur"
}
```

## Comportement des traductions

### Vérification des traductions existantes

Le système vérifie automatiquement si une traduction existe déjà :
- Si le champ est **vide** → la traduction est effectuée
- Si le champ a **déjà du contenu** → la traduction est ignorée (sauf avec `force: true`)

### Mise à jour des champs

- **Champs Mobility** (title, description) : mise à jour immédiate via JavaScript
- **Champs RichText** (context) : mise à jour de l'éditeur Trix via JavaScript

## Exemples d'utilisation

### Exemple 1 : Traduction d'un titre

```erb
<!-- Dans le formulaire -->
<%= f.text_field "title_fr" %>
<%= button_tag "IA", data: { 
  action: "click->mistral-translator#translateField",
  field: "title",
  from: "fr",
  to: "en",
  target_field: "title_en",
  url: translate_field_project_path(project)
} %>
```

### Exemple 2 : Traduction de tous les champs

```erb
<%= button_tag "Traduire tout avec IA", data: { 
  action: "click->mistral-translator#translateAll",
  from: "fr",
  url: translate_all_project_path(project)
} %>
```

## Personnalisation

### Modifier le style des boutons

Les boutons utilisent les classes Tailwind CSS. Vous pouvez les modifier dans `app/views/projects/_form.html.erb` :

```erb
<%= button_tag class: "votre-classe-css" do %>
  IA
<% end %>
```

### Modifier les messages de confirmation

Les messages de confirmation sont définis dans les attributs `data-confirm` :

```erb
data: { 
  confirm: "Votre message personnalisé"
}
```

### Ajouter des callbacks personnalisés

Vous pouvez étendre le contrôleur Stimulus dans `app/javascript/controllers/mistral_translator_controller.js` :

```javascript
translateField(event) {
  // Votre logique personnalisée avant la traduction
  this.beforeTranslate(event)
  
  // Traduction standard
  // ...
  
  // Votre logique personnalisée après la traduction
  this.afterTranslate(event)
}
```

## Dépannage

### Les boutons n'apparaissent pas

Vérifiez que :
1. Le projet est sauvegardé (`project.persisted?`)
2. La locale n'est pas la langue par défaut
3. Le contrôleur Stimulus est bien enregistré dans `app/javascript/controllers/index.js`

### Les traductions ne se mettent pas à jour

Vérifiez :
1. La console du navigateur pour les erreurs JavaScript
2. Les logs Rails pour les erreurs serveur
3. Que le champ cible existe bien (`target_field` dans les data attributes)

### Le formulaire ne se soumet plus

Assurez-vous qu'il n'y a pas de formulaires imbriqués. Les boutons de traduction doivent utiliser `button_tag` avec des actions Stimulus, pas `form_with`.

## Bonnes pratiques

1. **Traduire après avoir rempli le champ source** : Remplissez d'abord le champ en français avant de traduire
2. **Vérifier les traductions** : Les traductions automatiques peuvent nécessiter des ajustements
3. **Utiliser le contexte** : Le système utilise automatiquement le contexte "projet de développement web" pour améliorer la qualité
4. **Sauvegarder régulièrement** : Les traductions sont sauvegardées immédiatement, mais pensez à sauvegarder le formulaire principal

## Limitations

- Les traductions sont effectuées une par une (rate limiting de 2 secondes entre chaque requête)
- Les traductions de tous les champs peuvent prendre du temps (rechargement de page après 1.5 secondes)
- Les erreurs d'API sont affichées mais ne bloquent pas le formulaire principal


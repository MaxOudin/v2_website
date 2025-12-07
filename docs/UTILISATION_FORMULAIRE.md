# Utilisation de la traduction IA dans le formulaire

## Fonctionnalités

Le formulaire de projet inclut maintenant des boutons pour traduire automatiquement les champs avec l'IA Mistral.

### Boutons de traduction par champ

Chaque champ traduisible (titre, description, contexte) a un bouton "Traduire avec IA" qui apparaît :
- Uniquement pour les langues autres que la langue par défaut
- Uniquement si le projet est déjà sauvegardé (persisted)

### Bouton de traduction globale

Un bouton "Traduire tout avec IA" est disponible en bas du formulaire pour traduire tous les champs d'un coup.

## Utilisation

### Traduire un champ spécifique

1. Remplissez le champ dans la langue par défaut (français)
2. Cliquez sur le bouton "Traduire avec IA" à côté du champ dans la langue cible
3. La traduction apparaît automatiquement dans le champ

### Traduire tous les champs

1. Remplissez tous les champs dans la langue par défaut
2. Cliquez sur "Traduire tout avec IA" en bas du formulaire
3. Tous les champs seront traduits vers les autres langues disponibles

## Routes ajoutées

```ruby
resources :projects do
  member do
    post :translate_field    # Traduit un champ spécifique
    post :translate_all      # Traduit tous les champs
  end
end
```

## Actions du contrôleur

### `translate_field`

Traduit un champ spécifique d'un projet.

**Paramètres :**
- `field` : nom du champ à traduire (title, description, context)
- `from` : langue source (défaut: locale par défaut)
- `to` : langue cible (défaut: première langue disponible autre que la source)

**Exemple :**
```ruby
POST /projects/1/translate_field
{
  field: "title",
  from: "fr",
  to: "en"
}
```

### `translate_all`

Traduit tous les champs traduisibles d'un projet.

**Paramètres :**
- `from` : langue source (défaut: locale par défaut)
- `to` : langues cibles (défaut: toutes les langues sauf la source)

**Exemple :**
```ruby
POST /projects/1/translate_all
{
  from: "fr",
  to: ["en"]
}
```

## JavaScript

Le contrôleur Stimulus `mistral-translator` gère :
- Les réponses AJAX des traductions
- La mise à jour automatique des champs après traduction
- Les notifications de succès/erreur
- Le rechargement de la page après traduction globale

## Gestion des erreurs

En cas d'erreur :
- Un message d'erreur s'affiche
- Les logs Rails contiennent les détails de l'erreur
- L'utilisateur peut réessayer

## Notes importantes

1. **Projet doit être sauvegardé** : Les boutons n'apparaissent que si le projet existe déjà en base
2. **Langue par défaut** : Les traductions partent toujours de la langue par défaut (français)
3. **Traductions existantes** : Si une traduction existe déjà, elle sera remplacée
4. **Rate limiting** : Un délai est appliqué entre les requêtes pour respecter les limites de l'API

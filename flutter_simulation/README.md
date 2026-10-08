# Simulation de l'application mobile Habibo

Maquette interactive de l'application mobile de gestion d'entrepôt.
Elle sert à essayer le parcours et le design avant de les reporter dans la
vraie application (`flutter_application`), qui n'est pas modifiée.

Tout est fictif : aucune connexion au serveur, les données vivent en mémoire
et reviennent à zéro à chaque lancement.

## Lancer

```
cd flutter_simulation
flutter pub get
flutter run -d chrome
```

`flutter run -d windows` ou un téléphone Android fonctionnent aussi.
Sur un grand écran, l'application s'affiche dans un cadre de téléphone, avec
à gauche le parcours à suivre.

## Comptes de démonstration

| Rôle         | Matricule | Ce qu'il voit            |
|--------------|-----------|--------------------------|
| Opérateur    | 10482     | Les entrées et les sorties |
| Inventoriste | 10517     | Les inventaires          |

Sur l'écran de connexion, toucher un compte remplit le formulaire. Seul le
matricule est vérifié : n'importe quel mot de passe est accepté. On change de
rôle sans se déconnecter depuis Profil → « Passer en inventoriste ».

## Ce qui est simulé

Parcours déjà présent dans l'application réelle :

- connexion par matricule, journaux filtrés selon le rôle ;
- réception : scan du produit, DLV et DLC, quantité ;
- sortie : commandes, meilleur parcours, scan de vérification, pavé numérique ;
- inventaire : choix de l'emplacement, comptage.

Propositions ajoutées :

- écran de démarrage et session mémorisée ;
- barre de navigation à quatre onglets (Accueil, Opérations, Produits, Profil) ;
- accueil avec la carte « Reprendre », les compteurs du jour et les alertes ;
- onglet Produits et fiche produit (stock physique, réservé, disponible,
  emplacements, mouvements sur 7 jours, 30 jours ou 3 mois) ;
- photo du produit partout où il apparaît ;
- reste à servir quand le stock ne couvre pas la commande ;
- vibrations, écrans de chargement, états vides.

Le scanner est simulé : on touche un produit dans le plateau du bas pour
« lire » son code-barres. Toucher un autre produit que celui attendu montre
le refus.

## Organisation du code

| Dossier        | Contenu                                                    |
|----------------|------------------------------------------------------------|
| `lib/theme/`   | Couleurs et thème Habibo (les mêmes que l'application réelle) |
| `lib/data/`    | Modèles et `magasin.dart`, le faux entrepôt en mémoire     |
| `lib/widgets/` | Composants partagés et cadre de téléphone                  |
| `lib/screens/` | Un fichier par écran                                       |

## Captures d'écran

`flutter test --update-goldens` rejoue tout le parcours et enregistre une
image de chaque écran dans `test/captures/`.

## Crédits

Photos des produits : Open Food Facts, licence CC BY-SA.

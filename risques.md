# Risques du projet Habibo WMS

Audit du 11/10/2026. Backend Spring Boot, site React, application Flutter.

## 1. Périmètre et méthode

**Ce qui a été examiné**

| Partie | Volume | Comment |
|---|---|---|
| Backend | 221 fichiers Java (27 contrôleurs, 37 services, 33 repositories, 38 entités) | lecture de la configuration, de la sécurité, de toutes les routes et des services du stock, de la sortie, de l'entrée, de l'inventaire, des notifications et des fichiers |
| Tests | 8 classes, 21 tests | **exécutés** : 20 passent, 1 en erreur |
| Site React | 60 fichiers `.jsx` | lecture du routage, de la session, des appels réseau ; recherches ciblées |
| Application Flutter | 25 fichiers `.dart` | lecture des services, de la connexion, du parcours de sortie, de la configuration Android |
| Dépôt et déploiement | `git`, `docker-compose.yml`, `Dockerfile`, scripts SQL | lecture |

**Limites.** Sauf mention « exécuté », chaque constat vient de la lecture du code : il n'a pas été reproduit sur une base en marche. Les écrans n'ont pas été ouverts dans un navigateur ni sur un téléphone. Les 221 fichiers n'ont pas tous été lus ligne par ligne : les CRUD de référentiel (types, sociétés, racks, unités) ont été survolés.

**Échelle**

| Gravité | Sens |
|---|---|
| Critique | le stock devient faux, ou un accès non prévu est possible |
| Élevée | une fonction se bloque ou donne un résultat faux dans un cas réaliste |
| Moyenne | gêne, incohérence ou dette qui ne fausse pas les données |
| Faible | finition |

Probabilité : forte (arrivera avec des données réelles), moyenne (cas plausible), faible (demande une action volontaire ou rare).

---

## 2. Synthèse : les dix risques à traiter en premier

| # | Risque | Gravité | Probabilité | Effort |
|---|---|---|---|---|
| S1 | Une quantité négative ou nulle est acceptée au scan de sortie : le stock peut augmenter | Critique | Faible | 15 min |
| S2 | Deux réceptions du même article avec la même DLC et la même DLV font planter la sortie (erreur 500) | Critique | Forte | 1 à 2 h |
| S3 | Aucun contrôle de stock à la validation d'une sortie : un emplacement peut passer en négatif | Critique | Moyenne | 1 h |
| S4 | Le statut d'un journal se modifie librement : une sortie clôturée peut être rouverte et validée deux fois | Critique | Faible | 1 h |
| SEC1 | Mots de passe par défaut, secret JWT en clair, jeton valable 4,6 jours | Critique | Moyenne | 1 h |
| S5 | Une ligne prélevée n'est plus réservée mais pas encore sortie : double allocation possible | Élevée | Moyenne | 2 h |
| S6 | Aucun verrou à la génération du parcours ni au scan : deux opérateurs se marchent dessus | Élevée | Moyenne | 2 h |
| S8 | Valider un bon de reste sans picking en crée un autre, sans fin | Élevée | Moyenne | 1 h |
| Q3 | Tests : 1 test en erreur, aucun test du bon de reste, la suite dépend d'un MySQL local | Élevée | Forte | 2 h |
| P1 | Rien de ce qui a été livré cette semaine n'a été essayé dans un navigateur ou sur un téléphone | Élevée | Forte | 1 h |

---

## 3. Stock et règles métier

### S1. Quantité négative ou nulle au scan de sortie — Critique
- **Preuve.** `LignePickingService.scan`, ligne 366 : `Math.multiplyExact(scanLigneRequest.quantiteConditionnement(), ...)`. Le seul contrôle qui suit vérifie que le total ne **dépasse** pas la ligne. Aucun contrôle `> 0`. L'application mobile le vérifie, pas le serveur.
- **Conséquence.** Un appel direct à `POST /lignes-picking/scan` avec `-5` crée un prélèvement négatif. À la validation, il devient un mouvement de type SORTIE de quantité négative : le stock de l'emplacement **augmente**. Avec `null`, le serveur répond 500. Avec `0`, un prélèvement vide est enregistré.
- **Correction.** Refuser en 400 si la quantité est nulle, négative ou absente, en tête de `scan`.

### S2. Lot ambigu : même article, même DLC, même DLV — Critique
- **Preuve.** `DetailJournalRepository.findByArticleIdAndDlcAndDlv` renvoie un `Optional`, sans filtre de journal. Il est appelé par `LignePickingService.creerLigne` (ligne 134) et par `scan` (ligne 345).
- **Conséquence.** Dès que deux réceptions contiennent le même article avec les mêmes dates, la requête trouve deux lignes et lève une exception : la génération du parcours et le scan répondent 500. Avec des données sur plusieurs mois, ce cas arrivera.
- **Correction.** Transmettre l'identifiant du lot (`detailJournalId`) dans la proposition et dans la ligne, au lieu de le rechercher par ses dates. `findBestArticle` le connaît déjà (`GROUP BY detail.id`).

### S3. Aucun contrôle de stock à la validation — Critique
- **Preuve.** `MouvementStockService.validerSortie` (ligne 503) écrit les mouvements par `saveAll` (ligne 600) sans comparer au stock de l'emplacement.
- **Conséquence.** Si le stock a changé entre la réservation et la validation, l'emplacement devient négatif. Une valeur de −120 a déjà été observée sur l'article 2, emplacement 100.
- **Correction.** Avant `saveAll`, additionner les pièces par article et emplacement et refuser en 409 si le stock ne les couvre pas.

### S4. Statut de journal modifiable sans règle — Critique
- **Preuve.** `PUT /journaux-mouvements/{id}/statut` (`JournalMouvementController`, ligne 82) et `JournalMouvementService.update` (ligne 125) acceptent n'importe quel statut de journal. `validerSortie` ne se protège que par le statut `CLOTURE`.
- **Conséquence.** Un administrateur peut remettre une sortie clôturée « EN COURS » et la revalider : les mouvements de sortie sont écrits une seconde fois. `update` permet aussi de changer le **type** d'un journal déjà traité.
- **Correction.** Fermer ces deux voies (les statuts changent par les actions métier), et refuser la validation si des mouvements de sortie existent déjà pour ce journal.

### S5. Fenêtre « prélevée, pas encore sortie » — Élevée
- **Preuve.** `creerLigne` (lignes 262 à 275) ne compte comme réservées que les lignes `RESERVEE` et `EN_COURS`. Une ligne `PRELEVEE` ne compte plus, alors que le stock ne baisse qu'à la validation.
- **Conséquence.** Entre le prélèvement et la validation par l'administrateur, la même marchandise peut être proposée et réservée par une autre sortie.
- **Correction.** Compter aussi les lignes `PRELEVEE` tant que leur journal n'est pas clôturé. Décision D4 du todo.

### S6. Concurrence : pas de verrou — Élevée
- **Preuve.** Un seul `@Lock` dans le projet (`findByIdForUpdate`), aucun `@Version`. `genererMeilleurParcours` teste l'existence d'un picking actif (`CommandeService`, ligne 315) puis le crée, sans verrou. `scan` additionne les prélèvements puis insère.
- **Conséquence.** Deux opérateurs qui ouvrent la même sortie en même temps peuvent créer deux pickings. Deux scans simultanés sur la même ligne peuvent dépasser la quantité prévue. Deux générations parallèles lisent le même stock et réservent deux fois.
- **Correction.** Verrouiller le journal au début de la génération et de la validation, verrouiller la ligne au scan, ajouter `@Version` sur `Picking` et `LignePicking`.

### S7. Le contrôle de réservation ignore le lot — Élevée
- **Preuve.** `creerLigne`, ligne 254 : `trouverQuantiteTheorique(article, emplacement)`. La vue `v_stock_par_emplacement` regroupe par article et emplacement.
- **Conséquence.** Deux lots du même article dans le même emplacement : on peut sur-réserver l'un, et la sortie, rattachée au lot de la ligne, le fait passer en négatif.
- **Correction.** Calculer le disponible par lot (détail de réception) et non par article.

### S8. Bons de reste en cascade — Élevée
- **Preuve.** `validerSortie` accepte un journal sans picking et appelle `BonResteService.creerBonReste`. Le serveur ne distingue pas « parcours pas encore tenté » de « tenté, rien de disponible ».
- **Conséquence.** Valider un bon `-R1` qui attend du stock le clôture et crée un `-R1-R1`, puis un `-R1-R1-R1`. La seule protection est une confirmation dans la page de sortie.
- **Correction.** Mémoriser la tentative (statut « en attente de stock » ou picking vide) et refuser de valider un bon sans aucun prélèvement. Décision D5 du todo.

### S9. Le stock théorique reste faux après un constat d'absence — Élevée
- **Preuve.** `declarerImpossible` (ligne 504) ferme la ligne sans mouvement, ce qui est voulu. `InventaireService` calcule des écarts mais ne crée aucun ajustement.
- **Conséquence.** Le produit absent reste dans le stock du système et sera reproposé à la sortie suivante. Aucun mécanisme ne le corrige.
- **Correction.** Décision métier avec l'encadrant : mouvement d'ajustement à la validation d'un inventaire.

### S10. Article sans conditionnement — Élevée
- **Preuve.** `getArticleConditionnements().get(0)` dans `CommandeService` (lignes 169, 414, 429) et `MouvementStockService` (ligne 327). `BonResteService`, lignes 70 et 79 : un article sans conditionnement est ignoré par `continue`.
- **Conséquence.** Erreur 500 à la proposition d'emplacement ou à l'entrée en stock. Dans le bon de reste, le manque de cet article disparaît sans message.
- **Correction.** Refuser avec un message clair au lieu de l'index 0 ; signaler l'article ignoré au lieu de le sauter. La création guidée (`/articles/complet`) crée toujours un conditionnement, mais l'ancien `POST /articles` reste ouvert.

### S11. Une ligne non traitée bloque la validation — Élevée
- **Preuve.** `validerSortie`, ligne 537 : refus 409 si une ligne est encore `RESERVEE`.
- **Conséquence.** Voulu, pour ne pas fermer des lignes que personne n'a regardées. Mais la seule façon de débloquer est le bouton « Aucun produit ici » du mobile : le site n'offre aucune action équivalente. Si l'opérateur est absent, la sortie reste ouverte.
- **Correction.** Ajouter l'action sur la page de sortie (la route accepte déjà le rôle ADMIN).

### Risques moyens

| # | Risque | Preuve | Correction |
|---|---|---|---|
| S12 | Une boîte incomplète ne peut pas être prélevée : la validation exige un multiple du conditionnement | `validerSortie`, ligne 562 | précision des pièces à la sortie (A14 du todo) |
| S13 | Les pièces isolées ne sont jamais proposées (division entière) | `proposerEmplacement` | décision : les laisser, les proposer en fin de parcours ou les régulariser |
| S14 | Le surplus « en réserve » est invisible et inutilisable | vue `v_stock_par_emplacement` (`en_reserve = FALSE`) | décision métier, au minimum l'afficher |
| S15 | Le picking ne passe jamais seul à `TERMINE` ; `date_fin` reste vide | aucun appel depuis `scan` | le faire quand toutes les lignes sont fermées |
| S16 | Un journal se supprime ou se modifie à tout moment | `delete`, ligne 144 ; `InsertAllCommande` sans contrôle de statut | refuser après le premier mouvement ou picking |
| S17 | Unités : à l'inventaire, `quantite` seule change de sens selon le code scanné | `scanArticleInventaire`, branche « ancien comportement » | supprimer l'ancien comportement quand plus aucun client ne l'utilise |
| S18 | La DLC « vérifiée » au scan de sortie est renvoyée par l'application, pas lue par l'opérateur | `ecran_scan_sortie_maquette.dart` envoie `widget.ligne.dlc` | l'assumer, ou faire saisir la date |
| S19 | La validation ne redemande pas la confirmation côté serveur quand il n'y a pas de picking | contrôle fait seulement dans `AffectationSortie.jsx` | voir S8 |

---

## 4. Sécurité

### SEC1. Identifiants et secrets — Critique
- **Preuve.** `application.properties` : `spring.datasource.password=tiger`, compte `root`, `JWT_SECRET` en clair, `jwt.expiration` par défaut à 400 000 secondes (4,6 jours) sous un commentaire qui annonce une heure. `script-vrai.sql` crée tous les comptes, administrateur compris, avec le mot de passe `password`. `docker-compose.yml`, suivi par git, garde `tiger` comme valeur par défaut.
- **Point positif.** `application.properties` est ignoré par git et n'apparaît pas dans l'historique.
- **Conséquence.** Quiconque atteint le serveur avec le matricule `ADM001` et `password` est administrateur. Un jeton volé reste valable plusieurs jours et ne peut pas être révoqué.
- **Correction.** Changer les mots de passe des comptes, passer les secrets en variables d'environnement, ramener la durée à 1 heure, utiliser un compte MySQL dédié à l'application.

### SEC2. Identité prise dans la requête — Élevée
- **Preuve.** `LignePickingController`, ligne 48 : `request.userId()` vient du corps de la requête. Dans `scan`, le prélèvement est attribué à `lignePicking.getPicking().getUser()`, pas à l'utilisateur connecté.
- **Conséquence.** Un opérateur peut générer un parcours au nom d'un autre. Les prélèvements et les mouvements de stock sont signés du propriétaire du picking, même si quelqu'un d'autre a scanné. La traçabilité est fausse.
- **Correction.** Prendre l'utilisateur dans le jeton (`@AuthenticationPrincipal`), comme le font déjà les scans d'entrée et d'inventaire.

### SEC3. Rôles trop larges — Élevée
- **Preuve.** `SecurityConfig` : toutes les lectures sont ouvertes à tout utilisateur connecté (ligne 98). Les scans d'entrée et d'inventaire sont ouverts à tout rôle (lignes 61 à 70). La règle sur `/user/**` est en commentaire (lignes 56 et 57). Le projet ne contient aucun `@PreAuthorize`.
- **Conséquence.** Un opérateur lit la liste des utilisateurs (noms, matricules, e-mails) par `GET /user`. Un inventoriste peut scanner une réception, un opérateur un inventaire. Le mobile filtre les journaux par rôle, mais seulement à l'affichage. Aucune vérification qu'un opérateur travaille sur un journal qui lui est confié.
- **Correction.** Réserver `GET /user` à l'administrateur, limiter chaque scan au rôle concerné, filtrer les journaux côté serveur.

### SEC4. Connexion — Élevée
- **Preuve.** `UserService.login`, lignes 61 à 66 : deux messages distincts, « Utilisateur introuvable » et « Mot de passe incorrect », levés en `IllegalArgumentException`. Aucun gestionnaire pour cette exception. `server.error.include-message=always`.
- **Conséquence.** Le serveur répond 500 au lieu de 401 et indique si un matricule existe. Aucune limite de tentatives : le mot de passe peut être deviné par essais successifs.
- **Correction.** Un seul message et un code 401 ; limiter les tentatives ; retirer `include-message=always`.

### SEC5. Fichiers anciens servis tels quels — Moyenne
- **Preuve.** `GET /uploads/{nom}` renvoie le fichier avec le type détecté et `Content-Disposition: inline`. Le dossier `uploads/` contient encore des fichiers d'avant la règle « PDF seulement », dont un `.html`.
- **Conséquence.** Un fichier HTML ancien s'exécute dans le navigateur d'un utilisateur connecté qui ouvre son adresse.
- **Correction.** Ne servir que les PDF et les photos, ajouter `X-Content-Type-Options: nosniff`, supprimer les fichiers hérités.
- **Points positifs.** Les noms de fichiers sont nettoyés, le chemin est contrôlé, les PDF et les images sont vérifiés par leur signature, les photos publiques sont limitées au préfixe `photo-`.

### Risques moyens et faibles

| # | Risque | Preuve | Correction |
|---|---|---|---|
| SEC6 | Marquer une notification comme lue est réservé à l'administrateur | `PATCH /**` → ADMIN dans `SecurityConfig` | ouvrir `/notifications/**` à l'utilisateur connecté |
| SEC7 | Le rôle est dans le jeton : un changement de rôle ne prend effet qu'à l'expiration | `JwtService`, claim `roles` | durée courte (voir SEC1) |
| SEC8 | CORS limité à `localhost` : le site ne fonctionne pas depuis une autre machine | `WebConfig` | origine configurable |
| SEC9 | Le point WebSocket `/ws` est déclaré sans origine autorisée ni authentification propre, et n'est utilisé par personne | `WebSocketConfig` | le retirer tant qu'il ne sert pas |
| SEC10 | `GET /photos/**` est public | choix assumé : une balise `<img>` n'envoie pas de jeton | aucun, à expliquer en soutenance |
| SEC11 | Mobile : HTTP en clair, jeton en mémoire, APK de publication signé avec la clé de test, identifiant `com.example…` | `AndroidManifest.xml`, `build.gradle.kts` ligne 36 | acceptable en démonstration ; HTTPS et vraie clé pour un déploiement |
| SEC12 | Site : jeton dans `sessionStorage`, aucune garde de route, aucune gestion du 401, aucune déconnexion | `authService.js`, `main.jsx` | composant de route protégée, redirection sur 401, bouton de déconnexion |

**Vérifié sans défaut.** Aucune requête SQL construite par concaténation. Les notifications vérifient leur destinataire. Les valeurs insérées dans les PDF sont échappées. CSRF désactivé, ce qui est correct pour une API sans session.

---

## 5. Robustesse et qualité du code

| # | Risque | Gravité | Preuve | Correction |
|---|---|---|---|---|
| Q1 | Aucune validation d'entrée déclarative : un champ absent provoque une erreur 500 | Élevée | 0 annotation `jakarta.validation` dans le projet ; contrôles écrits à la main, inégaux | `@Valid` sur les requêtes principales |
| Q2 | Erreurs non gérées : `IllegalArgumentException`, violation de contrainte (matricule en double), entité introuvable renvoient 500 | Élevée | `GlobalExceptionHandler` ne traite que deux exceptions | gestionnaires pour ces cas, message neutre |
| Q3 | Tests insuffisants et fragiles | Élevée | **exécuté** : 21 tests, 1 erreur. `DemoApplicationTests` démarre l'application sur le MySQL local. Aucun test du bon de reste, de la ligne impossible, de la proposition, de la précision des pièces | profil de test H2, tests R10 du todo |
| Q4 | Le rapport d'inventaire plante si un comptage n'a pas d'utilisateur | Élevée | `InventaireService`, ligne 95 : `comptage.getUser().getUsername()` ; c'est l'erreur du test en échec. Les comptages insérés par `donnees_test_workflows.sql` n'ont pas d'utilisateur | tester la valeur nulle, rendre la colonne obligatoire |
| Q5 | Route cassée et inutilisée | Moyenne | `findByParticipantsId` : utilisateur écrit en dur (`user_id = 4`), colonnes incompatibles avec l'entité | la supprimer |
| Q6 | Code mort | Moyenne | `ConfirmationSortieService` (aucun appelant), `NotificationService.creer` (aucun appelant : aucune notification n'est jamais créée par le code), `UpdateCommandeAndDetailJournal` (ancien chemin), annotations vides `config/EnableMethodSecurity` et `service/Transactionnal` | supprimer |
| Q7 | Transactions inégales | Moyenne | 20 fichiers sur 37 dans `service/` sans aucun `@Transactional`, dont `ArticleService`, `UserService` et `InventaireService` qui écrivent ou lisent des relations ; `MouvementStockService` utilise l'annotation Jakarta, les autres celle de Spring | annoter les écritures, `readOnly` sur les lectures |
| Q8 | Services trop gros | Moyenne | `JournalMouvementService` 630 lignes, `MouvementStockService` 615, `LignePickingService` 540 | découper après la soutenance |
| Q9 | Schéma géré par `ddl-auto=update`, scripts SQL nombreux et en partie périmés | Moyenne | 26 fichiers dans `tables/`, dont des migrations déjà jouées et `simulation_mois_operations.sql` cassé | un seul script de création à jour, puis Flyway |
| Q10 | Journalisation bavarde | Faible | `show-sql=true`, `System.out.println` dans `InventaireController` ligne 28 | désactiver hors développement |
| Q11 | Nommage hérité | Faible | colonne `quantitePiecesPrelevee` en camelCase (stratégie de nommage littérale), dossier `Controller` avec majuscule | documenter, ne pas renommer avant la soutenance |

---

## 6. Site React

| # | Risque | Gravité | Preuve | Correction |
|---|---|---|---|---|
| W1 | Pages vides ou sans contenu | Élevée | `FicheProduit.jsx` et `AjoutVariante.jsx` vides ; route `/ficheProduit/:id` sans composant ; aucune route « page introuvable » | faire la fiche produit ou retirer la route |
| W2 | Pas de garde d'accès | Moyenne | toutes les routes sont publiques ; seule la connexion refuse un non-administrateur | route protégée |
| W3 | Session expirée non gérée | Moyenne | aucune gestion du code 401 dans 51 appels `fetch` répartis dans 26 fichiers | un client réseau commun |
| W4 | Aucune notification à l'écran | Moyenne | pas de cloche, pas d'appel à `/notifications` | F5 du todo |
| W5 | Chemins morts restants | Moyenne | `/upload`, `CreateTypeMouvementJournal`, routes `/new/…` en double, pages sans route | nettoyer `main.jsx` |
| W6 | Informations figées | Faible | « AR Administrateur » écrit en dur dans l'en-tête de la page de sortie | afficher l'utilisateur connecté |
| W7 | États vides, chargement, erreur inégaux | Faible | traités page par page | F3 du todo |

---

## 7. Application Flutter

| # | Risque | Gravité | Preuve | Correction |
|---|---|---|---|---|
| M1 | Le rack de départ est figé à 1 | Moyenne | `ecran_parcours_picking_maquette.dart`, ligne 14 : `rackDepartId = 1` | le choisir ou le déduire |
| M2 | Parcours généré à l'ouverture de l'écran, sans confirmation | Moyenne | `_chargerParcours` appelle la génération si aucun parcours n'existe | bouton explicite |
| M3 | Aucun délai d'attente sur les appels, sauf la connexion | Moyenne | un seul `.timeout` dans l'application | délai commun |
| M4 | Session perdue à chaque fermeture | Moyenne | le jeton reste en mémoire | session mémorisée (voir la simulation) |
| M5 | Écrans morts ou trompeurs | Moyenne | `SortiePage` n'est ouverte nulle part. `EcranInsertionSortie` reste accessible depuis la liste des commandes (toucher un emplacement proposé) : il fait scanner et saisir une quantité, affiche un message, mais n'envoie rien au serveur | supprimer le premier, retirer l'accès au second |
| M6 | Pas d'écran de fin de parcours | Moyenne | le parcours ne résume pas ce qui a été servi et ce qui manque | écran de la simulation |
| M7 | Le scan exige le code du conditionnement, que les articles n'ont pas tous | Élevée | `scan` : `findByCodeBarres` ; réception et inventaire refusent un code d'article dès qu'on envoie des conditionnements | accepter aussi le code de l'article (option B) |
| M8 | Unité non affichée à côté des champs de quantité | Faible | écrans de réception et de comptage | afficher « conditionnements », « pièces » |

---

## 8. Données, dépôt et déploiement

| # | Risque | Gravité | Preuve | Correction |
|---|---|---|---|---|
| D1 | Pas de jeu de données de démonstration fiable | Élevée | `simulation_mois_operations.sql` est cassé ; seules des données de test ciblées existent | F2 du todo |
| D2 | Aucune sauvegarde de la base | Élevée | pas de `mysqldump` de référence | un export avant chaque séance de démonstration |
| D3 | Beaucoup de travail non enregistré dans git | Élevée | 32 fichiers modifiés et 5 nouveaux non validés ; dernier commit le 08/10 : toute la sortie, le bon de reste et la précision des pièces ne sont dans aucun commit | valider par étapes |
| D4 | Documents internes Habibo | Moyenne | le catalogue (fiches produits, photos) est un document de l'entreprise ; le dépôt a une origine GitHub dont la visibilité n'a pas été vérifiée | ne pas le pousser sans accord |
| D5 | Photos de la simulation | Faible | images Open Food Facts, licence CC BY-SA | conserver la mention de la source |
| D6 | Conteneurs | Moyenne | l'image du backend tourne avec le compte `root` ; la base est exposée sur le port 3307 avec le compte `root` | compte applicatif, ne pas exposer la base |
| D7 | Schéma non reproductible | Moyenne | `journal_origine_id`, famille, unité, contenance, photo existent seulement par `ddl-auto` | les ajouter au script de création |

---

## 9. Risques pour la soutenance

| # | Risque | Parade |
|---|---|---|
| P1 | Les fonctions de la semaine (bon de reste, PDF, précision des pièces, « aucun produit ici », lien de sortie) n'ont pas été essayées à l'écran | dérouler la liste « À vérifier » du todo |
| P2 | Un écran vide ou une erreur 500 pendant la démonstration (S2, S10, Q4 sont les plus probables) | corriger S2, charger des données contrôlées, répéter le parcours exact |
| P3 | La démonstration mobile dépend du réseau | point d'accès du PC, adresse du serveur saisie à la connexion, APK installé à l'avance |
| P4 | Une question sur une limite connue (inventaire sans correction, stock en réserve, concurrence) | les présenter comme limites identifiées et perspectives, avec ce fichier à l'appui |
| P5 | Une modification demandée en direct sur Flutter | s'entraîner sur les dix modifications les plus probables |

---

## 10. Corrigé cette semaine

Ces points étaient des risques au début de la semaine. Ils sont implémentés et compilés ; le scénario A de la sortie incomplète a été vérifié par des requêtes SQL (lignes fermées, mouvements exacts, bon créé). Le reste est à essayer.

| Ancien risque | État |
|---|---|
| La génération du parcours échouait dès qu'un stock manquait | corrigé : génération partielle, liste vide sans erreur |
| Un lot de moins d'un conditionnement faisait échouer toute la génération | corrigé |
| La proposition ignorait les réservations des autres pickings | corrigé à la proposition ; `creerLigne` garde son propre calcul |
| Impossible de déclarer un produit absent | corrigé : action « aucun produit ici » |
| Une sortie sans prélèvement ne pouvait pas être clôturée | corrigé |
| Les lignes partielles restaient réservées après la clôture | corrigé |
| Mauvais picking choisi à la validation | corrigé dans `validerSortie` |
| Le manque d'une sortie était perdu | corrigé : bon de reste et PDF |
| L'inventoriste recevait un refus 403 au scan | corrigé, à retester |
| Deux routes répondaient à `GET /journaux-mouvements/{id}` | corrigé |
| Le scanner lisait hors du cadre | corrigé, à tester sur téléphone |
| Les erreurs du serveur s'affichaient sans motif sur le mobile | corrigé |
| Aucun lien vers la page de confirmation de sortie | corrigé |

---

## 11. Plan d'action proposé

**Avant la soutenance, dans cet ordre**

1. Essayer à l'écran ce qui a été livré (P1).
2. S1 : refuser une quantité nulle ou négative au scan.
3. S2 : identifier le lot par son identifiant.
4. S3 : contrôle de stock à la validation.
5. SEC1 : mots de passe, secret, durée du jeton.
6. S4 : fermer la modification libre du statut.
7. Q4 et Q3 : réparer le test d'inventaire, ajouter les tests du bon de reste.
8. M7 : accepter le code de l'article au scan.
9. D1, D2, D3 : données de démonstration, sauvegarde, commits.
10. W1 : fiche produit ou retrait de la route.

**À présenter comme limites connues et perspectives**

S5, S6, S7, S8, S9, S13, S14 (cohérence fine du stock et concurrence), SEC2 à SEC4 (identité et rôles), Q1, Q2, Q7 à Q9 (qualité), W2 à W5, M1 à M6.

---

## 12. Ce que l'audit n'a pas couvert

- Le comportement réel dans un navigateur et sur un téléphone.
- Les performances et le volume : aucune liste n'est paginée.
- Le moteur de recommandation d'emplacement (`OptimisationService`), lu seulement dans ses grandes lignes.
- Les CRUD de référentiel, survolés.
- Les dépendances : les versions n'ont pas été comparées aux avis de sécurité publiés.
- La visibilité du dépôt GitHub et son historique complet.

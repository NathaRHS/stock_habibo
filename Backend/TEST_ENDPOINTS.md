# JSON et endpoints de test

URL de base :

```text
http://localhost:8080
```

Pour les requêtes avec un corps JSON, ajouter l'en-tête :

```text
Content-Type: application/json
```

À l'exception de la connexion, les endpoints sont protégés. Après la connexion,
copier la valeur de `token` reçue et ajouter cet en-tête :

```text
Authorization: Bearer VOTRE_TOKEN
```

- Les requêtes `GET` nécessitent un utilisateur connecté.
- Les requêtes `POST`, `PUT` et `DELETE` nécessitent le rôle `ADMIN`.
- Les identifiants utilisés ci-dessous (`1`, `2`, etc.) sont des exemples à
  remplacer par les identifiants réellement retournés par l'API.

## Authentification et utilisateurs

### Connexion

```http
POST /user/login
```

```json
{
  "matricule": "ADM001",
  "password": "password"
}
```

Ces identifiants correspondent au compte de développement créé par
`tables/donnees_par_defaut.sql`. Changez ce mot de passe en dehors des tests
locaux.

Exemple de réponse :

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "user": {
    "id": 1,
    "username": "admin",
    "matricule": "ADM001",
    "email": "admin@example.com",
    "role": "ADMIN"
  }
}
```

### Créer un compte

```http
POST /user/creerCompte
```

```json
{
  "username": "inventoriste1",
  "matricule": "INV001",
  "email": "inventoriste1@example.com",
  "password": "MotDePasse123",
  "roleId": 3
}
```

`roleId` doit correspondre à un rôle existant.

## Rôles

### Lister les rôles

```http
GET /roles/showRoles
```

Aucun corps JSON.

## Types de produit

### Créer un type de produit

```http
POST /types-produits
```

```json
{
  "nomType": "BOISSON"
}
```

### Lister les types de produit

```http
GET /types-produits
```

Aucun corps JSON.

### Consulter un type de produit

```http
GET /types-produits/1
```

Aucun corps JSON.

### Modifier un type de produit

```http
PUT /types-produits/1
```

```json
{
  "nomType": "BOISSON GAZEUSE"
}
```

### Supprimer un type de produit

```http
DELETE /types-produits/1
```

Aucun corps JSON.

## Types de conditionnement

### Créer un type de conditionnement

```http
POST /types-conditionnements
```

```json
{
  "nomConditionnement": "CARTON"
}
```

Autres exemples : `PIECE` et `PACK`.

### Lister les types de conditionnement

```http
GET /types-conditionnements
```

Aucun corps JSON.

### Consulter un type de conditionnement

```http
GET /types-conditionnements/1
```

Aucun corps JSON.

### Modifier un type de conditionnement

```http
PUT /types-conditionnements/1
```

```json
{
  "nomConditionnement": "PALETTE"
}
```

### Supprimer un type de conditionnement

```http
DELETE /types-conditionnements/1
```

Aucun corps JSON.

## Articles

### Créer un article

```http
POST /articles
```

L'URL alternative `POST /articles/create` appelle la même fonction.

```json
{
  "nomArticle": "Coca-Cola 33 cl",
  "codeBar": "5449000000996",
  "typeProduitId": 1
}
```

`typeProduitId` doit correspondre à un type de produit existant.

### Lister les articles

```http
GET /articles
```

Aucun corps JSON.

### Consulter un article

```http
GET /articles/1
```

Aucun corps JSON.

### Modifier un article

```http
PUT /articles/1
```

```json
{
  "nomArticle": "Coca-Cola 50 cl",
  "codeBar": "5449000054227",
  "typeProduitId": 1
}
```

### Supprimer un article

```http
DELETE /articles/1
```

Aucun corps JSON.

## Racks

### Créer un rack

```http
POST /rack
```

```json
{
  "name": "RACK-A"
}
```

### Lister les racks

```http
GET /rack
```

Aucun corps JSON.

### Consulter un rack

```http
GET /rack/1
```

Aucun corps JSON.

### Modifier un rack

```http
PUT /rack/1
```

```json
{
  "name": "RACK-A1"
}
```

### Supprimer un rack

```http
DELETE /rack/1
```

Aucun corps JSON.

## Emplacements

### Créer un emplacement

```http
POST /emplacements
```

```json
{
  "nomEmplacement": "ZONE-A",
  "rackId": 1
}
```

`rackId` doit correspondre à un rack existant.

### Lister les emplacements

```http
GET /emplacements
```

Aucun corps JSON.

### Consulter un emplacement

```http
GET /emplacements/1
```

Aucun corps JSON.

### Modifier un emplacement

```http
PUT /emplacements/1
```

```json
{
  "nomEmplacement": "ZONE-B",
  "rackId": 1
}
```

### Supprimer un emplacement

```http
DELETE /emplacements/1
```

Aucun corps JSON.

## Stocks par étage

Ces endpoints lisent la vue SQL `v_stock_par_etage`. Il faut donc que la vue
existe et que des mouvements de stock aient déjà été enregistrés.

### Consulter tous les stocks par étage

```http
GET /stocks/etages
```

Aucun corps JSON.

Exemple de réponse :

```json
[
  {
    "articleId": 1,
    "etageId": 2,
    "quantiteStock": 150
  },
  {
    "articleId": 1,
    "etageId": 3,
    "quantiteStock": 45
  }
]
```

### Consulter le stock d'un article par étage

```http
GET /stocks/articles/1/etages
```

Aucun corps JSON.

Exemple de réponse :

```json
[
  {
    "articleId": 1,
    "etageId": 2,
    "quantiteStock": 150
  }
]
```

## Ordre de test conseillé

1. Vérifier qu'un compte administrateur existe dans la base.
2. Se connecter avec `POST /user/login` et copier le token.
3. Lister les rôles.
4. Créer un type de produit.
5. Créer les types de conditionnement.
6. Créer un article.
7. Créer un rack.
8. Créer un emplacement.
9. Tester les consultations de stock lorsque les étages et mouvements seront
   disponibles via leurs futurs endpoints.

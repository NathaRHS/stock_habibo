# Audit de risque — stock négatif

> Lecture du code uniquement (backend Spring, vues SQL, React, Flutter). Je n'ai pas pu interroger la base : je ne peux donc pas dire s'il existe déjà des stocks négatifs. La requête de détection est au §4.
> **Vérifié** = constaté dans le code avec le fichier. **À confirmer** = déduit, à essayer.
> Les références A3, A5, A6, A7, A9, A13, T3 renvoient à votre `todo.txt`.

---

## 1. Constat

**Oui, le stock peut devenir négatif.** Rien ne l'empêche, ni dans le code, ni dans la base :

- Le stock n'est jamais stocké : c'est la somme des mouvements signés (`v_stock_par_emplacement`). Une sortie est donc toujours acceptée par la base, quel que soit le stock restant.
- Aucune contrainte `CHECK` ni déclencheur sur `t_mouvement_stock`.
- Les sorties ne sont écrites qu'à un seul endroit, `MouvementStockService.validerSortie` (ligne 523 et suivantes), et **cette méthode ne vérifie pas le stock restant** (anomalie A13).
- La vue garde les négatifs sans les signaler : `HAVING SUM(...) <> 0` affiche −20 comme tout autre nombre.

---

## 2. Comment il devient négatif

### 2.1 Double réservation avant la validation — **Gravité élevée** (anomalie A3)
**Vérifié** dans `LignePickingService.java:282-297` et `:518-526`.

Le calcul du stock « disponible » retire seulement les lignes de picking en statut `RESERVEE` ou `EN_COURS`. Or :
1. L'opérateur prélève : la ligne passe à `PRELEVEE`.
2. **Le mouvement de stock n'est écrit qu'à la validation de la sortie par l'administrateur.**
3. Entre les deux, la ligne `PRELEVEE` n'est ni comptée comme réservée, ni déduite du stock.

Exemple : B001 contient 20 packs.
- Sortie S1 prélève 20 packs. La ligne est `PRELEVEE`, le stock est encore 20.
- Sortie S2 est générée : stock 20, réservé 0, donc elle réserve 20 packs sur B001.
- L'administrateur valide S1 puis S2 : deux mouvements de −20. **B001 = −20.**

### 2.2 Aucun contrôle à la validation — **Gravité élevée** (anomalie A13)
**Vérifié** : `validerSortie` crée les mouvements `SORTIE` (`:569-620`) puis fait `saveAll`, sans calculer le stock résultant. Même si 2.1 est corrigé un jour, rien n'arrêterait un autre chemin qui produirait un écart.

### 2.3 Validations simultanées — **Gravité moyenne**
**Vérifié** : le verrou `findByIdForUpdate` ne porte que sur **le journal** validé. Deux sorties différentes validées en même temps, sur les mêmes emplacements, passent toutes les deux. L'entrée n'a pas de verrou non plus (A9). Il n'existe aucun verrou sur l'emplacement ou l'article.

### 2.4 Journal modifié après le picking — **Gravité moyenne, à confirmer** (anomalie A7)
Un journal peut être modifié ou supprimé, et des commandes ajoutées, même après la génération du picking. Les lignes de picking peuvent alors ne plus correspondre aux commandes. Je n'ai pas reproduit le cas.

### 2.5 À ne pas confondre : le stock « fantôme » (pas négatif)
Si l'emplacement contient physiquement moins que le stock théorique (exemple vu : B001 propose 20, il y en a 19), la sortie laisse **1 pack en trop** dans le système. C'est l'inverse d'un négatif, mais même cause racine : l'inventaire ne corrige rien (A6, A15).

### 2.6 Chemin à risque inverse (stock trop haut)
L'ancien chemin `CommandeService.UpdateCommandeAndDetailJournal` crée des prélèvements qui ne sortent jamais du stock (A5). Ce n'est pas un négatif, mais il fausse le stock dans l'autre sens.

---

## 3. Conséquences constatées dans le code

| Où | Effet d'un stock négatif | Vérifié |
|---|---|---|
| **Vue `v_stock_par_emplacement`** | Le négatif est affiché comme une quantité normale, sans alerte. | Oui |
| **Suggestion d'emplacements** (`OptimisationService`) | `calculerConditionnementsPresents` divise des pièces négatives : le nombre de conditionnements présents peut devenir ≤ 0, donc la capacité libre **dépasse la capacité maximale** de la palette. Une suggestion peut surcharger l'emplacement. | Oui (calcul), à confirmer en exécution |
| **Filtre des candidats** (`EmplacementRepository`, `rechercherEmplacementsCandidats`) | Seuls les stocks `> 0` d'un autre article rendent un emplacement indisponible. Un emplacement négatif d'un autre article est donc considéré libre par la requête, puis écarté plus loin par le code Java : comportement incohérent entre les deux couches. | Oui |
| **Tableau de bord** (`etatDuStock`) | Le total d'un article additionne tous ses emplacements : un −20 sur B001 **masque** 20 pièces réellement présentes ailleurs. Un total ≤ 0 compte comme « rupture ». | Oui |
| **Page Entrepôt** | Quantités et taux de remplissage négatifs. | À confirmer |
| **Inventaire** | L'écart se calcule contre un théorique négatif, donc un écart faussé. | Oui (`trouverQuantiteTheorique`) |
| **Anomalies par emplacement** (idée en cours) | Un théorique faux fausse le taux d'anomalies. | Oui |

---

## 4. Détecter les négatifs existants

À lancer sur la base `stock_habibo` :

```sql
SELECT v.emplacement_id,
       e.nom_emplacement,
       a.nom_article,
       v.quantite_stock
FROM v_stock_par_emplacement v
JOIN t_emplacement e ON e.id = v.emplacement_id
JOIN t_article     a ON a.id = v.article_id
WHERE v.quantite_stock < 0
ORDER BY v.quantite_stock;
```

Pour comprendre d'où vient un négatif précis (en reprenant la vue `v_mouvement_signe`) :

```sql
SELECT date_mouvement, nom_type_mouvement, quantite_signee, id
FROM v_mouvement_signe
WHERE emplacement_id = 44 AND article_id = 3
ORDER BY date_mouvement, id;
```

Le point où la somme cumulée passe sous zéro est la sortie fautive.

---

## 5. Risques classés

| # | Risque | Probabilité | Impact | Priorité |
|---|---|---|---|---|
| 1 | Double réservation (§2.1) | Élevée dès que deux sorties visent le même article | Stock faux, suggestions fausses | **P1** |
| 2 | Pas de contrôle à la validation (§2.2) | Certaine (le contrôle n'existe pas) | Un négatif est accepté sans alerte | **P1** |
| 3 | Validations simultanées (§2.3) | Faible avec peu d'utilisateurs | Même effet que 1 | P2 |
| 4 | Suggestion qui surcharge (§3) | Conditionnée par 1 et 2 | Emplacement dépassé | P2 |
| 5 | Journal modifié après picking (§2.4) | À confirmer | Lignes incohérentes | P2 |
| 6 | Négatif invisible dans les écrans | Certaine | On ne le voit pas, donc on ne le corrige pas | P2 |
| 7 | Aucun moyen de corriger (A6) | Certaine | Un négatif ou un fantôme reste indéfiniment | P2 |

---

## 6. Corrections proposées, dans l'ordre

1. **Contrôle à la validation (A13)** — le plus petit changement, le plus utile. Dans `validerSortie`, après avoir regroupé les mouvements, calculer le stock résultant par (emplacement, article) et refuser en `409` en citant l'emplacement fautif. Rien ne s'écrit si un seul est négatif.
2. **Compter les lignes `PRELEVEE` non validées comme réservées (A3)** — dans `LignePickingService` (lignes 289 et 525), `CommandeService.proposerEmplacement` et `OptimisationService.filtrerEmplacementsCandidats`. Ainsi le stock « disponible » reste juste entre le prélèvement et la validation. Alternative plus radicale : écrire le mouvement de sortie à chaque scan au lieu de la validation, mais cela change le workflow (annulation d'un scan).
3. **Verrouiller à la validation** — verrou pessimiste sur les stocks concernés (triés par identifiant pour éviter les blocages), ou une validation à la fois au niveau de l'application.
4. **Garde-fou en base** — un déclencheur `BEFORE INSERT` sur `t_mouvement_stock` qui refuse une sortie dont le stock résultant serait négatif. C'est la dernière ligne de défense, y compris contre un futur chemin d'écriture oublié.
5. **Rendre le négatif visible** — alerte rouge dans la page Entrepôt, compteur « emplacements en négatif » sur le tableau de bord, notification à l'administrateur (nouveau type de notification).
6. **Capacité jamais supérieure au maximum** — dans `OptimisationService.calculerConditionnementsPresents`, ramener les pièces présentes à `max(0, …)`.
7. **Corriger l'existant** — après détection (§4), poser des mouvements d'ajustement. Cela suppose l'ajustement automatique à la validation de l'inventaire (A6), déjà dans vos idées.
8. **Tests** — le scénario « deux sorties sur le même emplacement » (T3 de votre `todo.txt`) doit échouer avec le code actuel et réussir après les corrections 1 et 2.

## 7. Ce que je ne peux pas affirmer
- S'il existe des stocks négatifs aujourd'hui : cela dépend de vos données, d'où la requête du §4.
- L'effet exact d'un négatif sur la page Entrepôt (je n'ai lu que le calcul).
- Si le §2.4 produit réellement un négatif : il faudrait le reproduire.

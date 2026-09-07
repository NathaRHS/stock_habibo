 - Creation d'une nouvelle table commande 
    commande:
    - id
    - idJournal
    - idProduit
    - Etat (mety na tsia)
    - Remarques
    - Quantité demandé 
    - Quantité réel 
    - matriculeUserNicheck

- Creation table t_temp_mouvement_stock

Pages liste produits commande: 
    - liste de tous les produits dans selon le journal
    - Quand il cliquera sur le produit , il aura un pop up des emplacements où il y a le produit
    - Il validera ensuite sinon il mettra une remarque
        - Si valider -> mise à jour DetailJournal et miseAJourCommande
        - Sinon , remarque obligatoire 


Problèmes:
- Plusieurs opérateurs quand ils cliqueront sur le produit , pourraient rechercher le même produit



Fonctions:

- Fonction mi créer liste ana commande
- Fonction mi mettre à jour an'ilay commande 
- Fonction creerTout() mi create DetailJournal sy miantso ilay mettreAJourCommande


package com.example.demo.entity;

/**
 * Liste fermee des actions enregistrees dans le journal des utilisateurs.
 * Le libelle est la fin de la phrase affichee : "STG-001 a valide un journal".
 *
 * Toute valeur ajoutee ici doit aussi l'etre dans le CHECK de t_journal_user
 * (Backend/tables/journal_user.sql).
 */
public enum TypeEvenementUser {

    // Authentification et comptes
    CONNEXION_REUSSIE("s'est connecté"),
    CONNEXION_ECHOUEE("a échoué à se connecter"),
    DECONNEXION("s'est déconnecté"),
    COMPTE_CREE("a créé un compte"),
    PHOTO_UTILISATEUR_CHANGEE("a changé une photo de profil"),

    // Articles
    ARTICLE_CREE("a créé un article"),
    VARIANTE_CREEE("a créé une variante"),
    ARTICLE_SUPPRIME("a supprimé un article"),
    PHOTO_ARTICLE_CHANGEE("a changé la photo d'un article"),

    // Journaux de mouvement
    JOURNAL_CREE("a créé un journal"),
    JOURNAL_MODIFIE("a modifié un journal"),
    JOURNAL_SUPPRIME("a supprimé un journal"),
    JOURNAL_VALIDE("a validé un journal"),
    MODIFICATION_DEMANDEE("a demandé une modification"),
    ENTREE_STOCK_VALIDEE("a affecté une entrée en stock"),
    SORTIE_CONFIRMEE("a confirmé une sortie"),

    // Travail de terrain
    PARTICIPATION_DEBUTEE("a commencé une tâche"),
    PARTICIPATION_TERMINEE("a terminé une tâche"),
    COMMANDES_AJOUTEES("a ajouté des commandes"),
    PARCOURS_GENERE("a généré un parcours de picking"),
    AUCUN_PRODUIT_DECLARE("a déclaré « aucun produit »"),

    // Référentiels (racks, emplacements, sociétés, unités, types...)
    REFERENTIEL_CREE("a créé un élément"),
    REFERENTIEL_MODIFIE("a modifié un élément"),
    REFERENTIEL_SUPPRIME("a supprimé un élément");

    private final String libelle;

    TypeEvenementUser(String libelle) {
        this.libelle = libelle;
    }

    public String getLibelle() {
        return libelle;
    }
}

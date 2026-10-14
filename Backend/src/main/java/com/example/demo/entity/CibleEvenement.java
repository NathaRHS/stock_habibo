package com.example.demo.entity;

/** Type d'objet sur lequel porte une action du journal des utilisateurs. */
public enum CibleEvenement {
    USER("utilisateur"),
    ARTICLE("article"),
    JOURNAL("journal"),
    COMMANDE("commande"),
    LIGNE_PICKING("ligne de picking"),
    RACK("rack"),
    EMPLACEMENT("emplacement"),
    SOCIETE("société"),
    UNITE("unité"),
    TYPE_PRODUIT("type de produit"),
    TYPE_CONDITIONNEMENT("type de conditionnement"),
    CONDITIONNEMENT("conditionnement"),
    PALETTE("capacité palette"),
    TYPE_MOUVEMENT("type de mouvement"),
    STATUT("statut"),
    PICKING("picking");

    private final String libelle;

    CibleEvenement(String libelle) {
        this.libelle = libelle;
    }

    public String getLibelle() {
        return libelle;
    }
}

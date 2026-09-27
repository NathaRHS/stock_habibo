package com.example.demo.entity;

import java.util.Arrays;

/**
 * Statuts autorises pour le workflow d'un journal de mouvement.
 *
 * La table t_statut reste le referentiel commun en base. Cet enum protege les
 * regles propres aux journaux et empeche de leur attribuer un statut reserve a
 * une autre entite, par exemple PRELEVEE.
 */
public enum StatutJournalMouvementCode {
    EN_COURS("EN COURS"),
    EN_ATTENTE("EN ATTENTE"),
    VALIDE("VALIDE"),
    MODIFIE("MODIFIE");

    private final String nom;

    StatutJournalMouvementCode(String nom) {
        this.nom = nom;
    }

    public String getNom() {
        return nom;
    }

    public static StatutJournalMouvementCode depuisNom(String nom) {
        if (nom == null) {
            throw new IllegalArgumentException("Le nom du statut est obligatoire");
        }

        return Arrays.stream(values())
                .filter(statut -> statut.nom.equalsIgnoreCase(nom.trim()))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException(
                        "Statut non autorise pour un journal de mouvement : " + nom));
    }

    public static boolean accepte(String nom) {
        try {
            depuisNom(nom);
            return true;
        } catch (IllegalArgumentException exception) {
            return false;
        }
    }
}

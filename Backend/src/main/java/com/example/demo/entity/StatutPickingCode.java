package com.example.demo.entity;

import java.util.Collection;
import java.util.List;

/**
 * Statuts autorises pour un picking.
 *
 * La table t_statut_picking est le referentiel de ces statuts en base. Le nom
 * stocke en base est exactement le nom de la constante (GENERE, EN_COURS...).
 */
public enum StatutPickingCode {
    GENERE,
    EN_COURS,
    TERMINE,
    ANNULE;

    public String getNom() {
        return name();
    }

    public static StatutPickingCode depuisNom(String nom) {
        if (nom == null) {
            throw new IllegalArgumentException("Le nom du statut est obligatoire");
        }
        return valueOf(nom.trim());
    }

    public static List<String> versNoms(Collection<StatutPickingCode> codes) {
        return codes.stream().map(StatutPickingCode::getNom).toList();
    }
}

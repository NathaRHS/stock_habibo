package com.example.demo.entity;

import java.util.Collection;
import java.util.List;

/**
 * Statuts autorises pour une ligne de picking.
 *
 * La table t_statut_ligne_picking est le referentiel de ces statuts en base. Le
 * nom stocke en base est exactement le nom de la constante (RESERVEE, ...).
 */
public enum StatutLignePickingCode {
    RESERVEE,
    EN_COURS,
    PRELEVEE,
    ANNULEE,
    IMPOSSIBLE;

    public String getNom() {
        return name();
    }

    public static StatutLignePickingCode depuisNom(String nom) {
        if (nom == null) {
            throw new IllegalArgumentException("Le nom du statut est obligatoire");
        }
        return valueOf(nom.trim());
    }

    public static List<String> versNoms(Collection<StatutLignePickingCode> codes) {
        return codes.stream().map(StatutLignePickingCode::getNom).toList();
    }
}

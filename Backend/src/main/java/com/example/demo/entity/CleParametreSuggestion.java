package com.example.demo.entity;

import java.math.BigDecimal;

/**
 * Liste fermee des reglages de la suggestion d'emplacements, avec leur valeur
 * par defaut. Les poids reprennent les valeurs ecrites jusqu'ici dans
 * OptimisationService : tant que rien n'est modifie, le classement ne change pas.
 */
public enum CleParametreSuggestion {

    // Poids du score final, en pourcentage (leur somme doit faire 100).
    POIDS_PROXIMITE("poids_proximite", "25", "Importance de la proximité de la sortie (%)"),
    POIDS_CAPACITE("poids_capacite", "30", "Importance de la capacité disponible (%)"),
    POIDS_FIABILITE("poids_fiabilite", "30", "Importance de la fiabilité de l'emplacement (%)"),
    POIDS_REGROUPEMENT("poids_regroupement", "15", "Importance du regroupement d'un même article (%)"),

    // Score (0 à 100) donné à un emplacement encore vide.
    SCORE_EMPLACEMENT_VIDE("score_emplacement_vide", "60", "Score donné à un emplacement vide (0 à 100)"),

    // Anomalies d'inventaire : un écart est ignoré sous la tolérance, mineur
    // jusqu'au seuil, majeur au-delà (écarts relatifs au stock théorique, en %).
    ANOMALIE_TOLERANCE_PCT("anomalie_tolerance_pct", "2", "Écart toléré, en % du stock théorique"),
    ANOMALIE_SEUIL_MAJEURE_PCT("anomalie_seuil_majeure_pct", "5", "Écart à partir duquel l'anomalie est majeure (%)"),
    ANOMALIE_POIDS_MINEURE("anomalie_poids_mineure", "0.25", "Poids d'une anomalie mineure"),
    ANOMALIE_POIDS_MAJEURE("anomalie_poids_majeure", "1", "Poids d'une anomalie majeure"),
    ANOMALIE_PENALITE_POINTS("anomalie_penalite_points", "10", "Points de fiabilité retirés par anomalie pondérée"),
    ANOMALIE_FENETRE_JOURS("anomalie_fenetre_jours", "90", "Période des comptages pris en compte (jours)"),
    ANOMALIE_MIN_COMPTAGES("anomalie_min_comptages", "3", "Comptages minimum avant d'écarter un emplacement"),

    // Exclusion d'un emplacement peu fiable (désactivée au départ : 0 = non, 1 = oui).
    EXCLUSION_ACTIVE("exclusion_active", "0", "Écarter les emplacements peu fiables (0 = non, 1 = oui)"),
    EXCLUSION_TAUX_PCT("exclusion_taux_pct", "50", "Taux d'anomalies à partir duquel on écarte (%)");

    private final String cle;
    private final BigDecimal valeurParDefaut;
    private final String description;

    CleParametreSuggestion(String cle, String valeurParDefaut, String description) {
        this.cle = cle;
        this.valeurParDefaut = new BigDecimal(valeurParDefaut);
        this.description = description;
    }

    public String getCle() {
        return cle;
    }

    public BigDecimal getValeurParDefaut() {
        return valeurParDefaut;
    }

    public String getDescription() {
        return description;
    }
}

package com.example.demo.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Referentiel des statuts d'un journal de mouvement.
 *
 * Les valeurs possibles sont definies par l'enum StatutJournalMouvementCode.
 * Les regles de transition restent dans les services. Chaque changement de
 * statut est trace dans HistoriqueJournalMouvementStatut.
 */
@Entity
@Table(name = "t_statut_journal_mouvement")
public class StatutJournalMouvement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nom", nullable = false, unique = true, length = 50)
    private String nom;

    public StatutJournalMouvement() {
    }

    public StatutJournalMouvement(String nom) {
        this.nom = nom;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }
}

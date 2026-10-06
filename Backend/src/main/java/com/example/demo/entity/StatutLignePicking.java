package com.example.demo.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Referentiel des statuts d'une ligne de picking.
 *
 * Les valeurs possibles sont definies par l'enum StatutLignePickingCode. Chaque
 * changement de statut est trace dans HistoriqueLignePickingStatut.
 */
@Entity
@Table(name = "t_statut_ligne_picking")
public class StatutLignePicking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nom", nullable = false, unique = true, length = 50)
    private String nom;

    public StatutLignePicking() {
    }

    public StatutLignePicking(String nom) {
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

package com.example.demo.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Referentiel commun des statuts du WMS.
 *
 * Les regles de transition restent definies par les enums et les services.
 * Cette entite servira a unifier les statuts stockes en base et a alimenter
 * l'historique des changements de statut.
 */
@Entity
@Table(name = "t_statut")
public class Statut {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nom", nullable = false, unique = true, length = 50)
    private String nom;

    public Statut() {
    }

    public Statut(String nom) {
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

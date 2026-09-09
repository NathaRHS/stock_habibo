package com.example.demo.entity;

import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;

@Entity
@Table(name = "t_statut_prelevement")
public class StatutPrelevement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nom_statut", nullable = false, unique = true, length = 50)
    private String nomStatut;

    @OneToMany(mappedBy = "statutPrelevement")
    private List<Prelevement> prelevements = new ArrayList<>();

    public StatutPrelevement() {
    }

    public StatutPrelevement(String nomStatut) {
        this.nomStatut = nomStatut;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNomStatut() {
        return nomStatut;
    }

    public void setNomStatut(String nomStatut) {
        this.nomStatut = nomStatut;
    }

    public List<Prelevement> getPrelevements() {
        return prelevements;
    }

    public void setPrelevements(List<Prelevement> prelevements) {
        this.prelevements = prelevements;
    }
}

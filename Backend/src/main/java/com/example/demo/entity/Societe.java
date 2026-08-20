package com.example.demo.entity;

import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.*;

@Entity
@Table(name = "t_societe")
public class Societe {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nom_societe", nullable = false, unique = true)
    private String nomSociete;

    @OneToMany(mappedBy = "fournisseur")
    private List<JournalMouvement> journaux = new ArrayList<>();

    public Societe() {
    }

    public Societe(String nomSociete) {
        this.nomSociete = nomSociete;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNomSociete() {
        return nomSociete;
    }

    public void setNomSociete(String nomSociete) {
        this.nomSociete = nomSociete;
    }

    public List<JournalMouvement> getJournaux() {
        return journaux;
    }

    public void setJournaux(List<JournalMouvement> journaux) {
        this.journaux = journaux;
    }

}

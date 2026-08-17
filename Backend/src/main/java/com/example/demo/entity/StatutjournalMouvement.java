package com.example.demo.entity;

import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.*;

@Entity
@Table(name = "t_statut_journal_mouvement")
public class StatutjournalMouvement {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToMany(mappedBy = "statutJournalMouvement")
    private List<JournalMouvement> journaux = new ArrayList<>();

    @Column(name = "nom_statut", nullable = false, unique = true, length = 50)
    private String nomStatut;

    public StatutjournalMouvement() {
    }

    public StatutjournalMouvement(String nomStatut) {
        this.nomStatut = nomStatut;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public List<JournalMouvement> getJournaux() {
        return journaux;
    }

    public void setJournaux(List<JournalMouvement> journaux) {
        this.journaux = journaux;
    }

    public String getNomStatut() {
        return nomStatut;
    }

    public void setNomStatut(String nomStatut) {
        this.nomStatut = nomStatut;
    }

}

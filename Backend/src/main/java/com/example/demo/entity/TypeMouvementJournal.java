package com.example.demo.entity;

import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.*;

@Entity
@Table(name = "t_type_mouvement_journal")
public class TypeMouvementJournal {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nom_type_mouvement", nullable = false, unique = true, length = 50)
    private String nomTypeMouvement;

    @Column(name = "sens", nullable = false)
    private Short sens;

    @OneToMany(mappedBy = "typeMouvementJournal")
    private List<JournalMouvement> journalMouvements = new ArrayList<>();

    public TypeMouvementJournal() {
    }

    public TypeMouvementJournal(String nomTypeMouvement, Short sens) {
        this.nomTypeMouvement = nomTypeMouvement;
        setSens(sens);
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNomTypeMouvement() {
        return nomTypeMouvement;
    }

    public void setNomTypeMouvement(String nomTypeMouvement) {
        this.nomTypeMouvement = nomTypeMouvement;
    }

    public Short getSens() {
        return sens;
    }

    public void setSens(Short sens) {
        if (sens == null || (sens != -1 && sens != 1)) {
            throw new IllegalArgumentException("Le sens doit valoir -1 ou 1");
        }
        this.sens = sens;
    }

    public List<JournalMouvement> getJournalMouvements() {
        return journalMouvements;
    }

    public void setJournalMouvements(List<JournalMouvement> journalMouvements) {
        this.journalMouvements = journalMouvements;
    }

}

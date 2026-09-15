package com.example.demo.entity;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

/**
 * Tournee de picking generee pour un journal de sortie.
 */
@Entity
@Table(name = "t_picking")
public class Picking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "date_generation_picking", nullable = false)
    private LocalDateTime dateGenerationPicking;

    @Column(name = "date_debut")
    private LocalDateTime dateDebut;

    @Column(name = "date_fin")
    private LocalDateTime dateFin;

    @ManyToOne(optional = false)
    @JoinColumn(name = "journal_mouvement_id", nullable = false)
    private JournalMouvement journalMouvement;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(optional = false)
    @JoinColumn(name = "rack_depart_id", nullable = false)
    private Rack rackDepart;

    @Enumerated(EnumType.STRING)
    @Column(name = "statut", nullable = false, length = 20)
    private StatutPicking statut = StatutPicking.GENERE;

    @OneToMany(mappedBy = "picking", cascade = { CascadeType.PERSIST, CascadeType.MERGE })
    private List<LignePicking> lignes = new ArrayList<>();

    public Picking() {
    }

    public Picking(JournalMouvement journalMouvement, User user, Rack rackDepart) {
        this.journalMouvement = journalMouvement;
        this.user = user;
        this.rackDepart = rackDepart;
        this.dateGenerationPicking = LocalDateTime.now();
        this.statut = StatutPicking.GENERE;
    }

    @PrePersist
    private void initialiserAvantCreation() {
        if (dateGenerationPicking == null) {
            dateGenerationPicking = LocalDateTime.now();
        }
        if (statut == null) {
            statut = StatutPicking.GENERE;
        }
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public LocalDateTime getDateGenerationPicking() {
        return dateGenerationPicking;
    }

    public void setDateGenerationPicking(LocalDateTime dateGenerationPicking) {
        this.dateGenerationPicking = dateGenerationPicking;
    }

    public LocalDateTime getDateDebut() {
        return dateDebut;
    }

    public void setDateDebut(LocalDateTime dateDebut) {
        this.dateDebut = dateDebut;
    }

    public LocalDateTime getDateFin() {
        return dateFin;
    }

    public void setDateFin(LocalDateTime dateFin) {
        this.dateFin = dateFin;
    }

    public JournalMouvement getJournalMouvement() {
        return journalMouvement;
    }

    public void setJournalMouvement(JournalMouvement journalMouvement) {
        this.journalMouvement = journalMouvement;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public Rack getRackDepart() {
        return rackDepart;
    }

    public void setRackDepart(Rack rackDepart) {
        this.rackDepart = rackDepart;
    }

    public StatutPicking getStatut() {
        return statut;
    }

    public void setStatut(StatutPicking statut) {
        this.statut = statut;
    }

    public List<LignePicking> getLignes() {
        return lignes;
    }

    public void setLignes(List<LignePicking> lignes) {
        this.lignes = lignes;
    }

    public void ajouterLigne(LignePicking ligne) {
        lignes.add(ligne);
        ligne.setPicking(this);
    }
}

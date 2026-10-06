package com.example.demo.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

/**
 * Une ligne par changement de statut d'un journal de mouvement.
 * Une ligne d'historique n'est jamais modifiee : on insere, on ne met pas a jour.
 */
@Entity
@Table(name = "t_historique_journal_mouvement_statut")
public class HistoriqueJournalMouvementStatut {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "journal_mouvement_id", nullable = false)
    private JournalMouvement journalMouvement;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "statut_id", nullable = false)
    private StatutJournalMouvement statut;

    @Column(name = "date_changement", nullable = false)
    private LocalDateTime dateChangement;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    protected HistoriqueJournalMouvementStatut() {
    }

    public HistoriqueJournalMouvementStatut(
            JournalMouvement journalMouvement,
            StatutJournalMouvement statut,
            LocalDateTime dateChangement,
            User user) {
        this.journalMouvement = journalMouvement;
        this.statut = statut;
        this.dateChangement = dateChangement;
        this.user = user;
    }

    public Long getId() {
        return id;
    }

    public JournalMouvement getJournalMouvement() {
        return journalMouvement;
    }

    public StatutJournalMouvement getStatut() {
        return statut;
    }

    public LocalDateTime getDateChangement() {
        return dateChangement;
    }

    public User getUser() {
        return user;
    }
}

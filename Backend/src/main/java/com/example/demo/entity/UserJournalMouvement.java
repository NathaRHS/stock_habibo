package com.example.demo.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(
        name = "t_user_journal_mouvement",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_user_journal_mouvement",
                columnNames = { "journal_mouvement_id", "user_id" }))
public class UserJournalMouvement {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "journal_mouvement_id", nullable = false)
    private JournalMouvement journalMouvement;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "statut_participation", nullable = false, length = 20)
    private StatutParticipation statutParticipation;

    @Column(name = "date_debut", nullable = false)
    private LocalDateTime dateDebut;

    @Column(name = "date_fin")
    private LocalDateTime dateFin;

    public UserJournalMouvement() {
    }

    public UserJournalMouvement(JournalMouvement journalMouvement, User user) {
        this.journalMouvement = journalMouvement;
        this.user = user;
        this.statutParticipation = StatutParticipation.EN_COURS;
        this.dateDebut = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public JournalMouvement getJournalMouvement() {
        return journalMouvement;
    }

    public User getUser() {
        return user;
    }

    public StatutParticipation getStatutParticipation() {
        return statutParticipation;
    }

    public void setStatutParticipation(StatutParticipation statutParticipation) {
        this.statutParticipation = statutParticipation;
    }

    public LocalDateTime getDateDebut() {
        return dateDebut;
    }

    public LocalDateTime getDateFin() {
        return dateFin;
    }

    public void setDateFin(LocalDateTime dateFin) {
        this.dateFin = dateFin;
    }
}

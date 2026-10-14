package com.example.demo.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

/**
 * Une ligne par action importante d'un utilisateur : qui, quoi, sur quoi, quand.
 * Une ligne n'est jamais modifiee : on insere, on ne met pas a jour.
 */
@Entity
@Table(name = "t_journal_user")
public class JournalUser {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Vide pour une connexion echouee (matricule inconnu) ou une action du systeme.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    // Ce qui a ete tape quand la connexion echoue.
    @Column(name = "matricule_saisi", length = 100)
    private String matriculeSaisi;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 40)
    private TypeEvenementUser type;

    @Enumerated(EnumType.STRING)
    @Column(name = "cible_type", length = 40)
    private CibleEvenement cibleType;

    @Column(name = "cible_id")
    private Long cibleId;

    @Column(name = "details", length = 500)
    private String details;

    // Heure du serveur, jamais celle du navigateur ou du telephone.
    @Column(name = "date_evenement", nullable = false)
    private LocalDateTime dateEvenement;

    protected JournalUser() {
    }

    public JournalUser(
            User user,
            String matriculeSaisi,
            TypeEvenementUser type,
            CibleEvenement cibleType,
            Long cibleId,
            String details) {
        this.user = user;
        this.matriculeSaisi = matriculeSaisi;
        this.type = type;
        this.cibleType = cibleType;
        this.cibleId = cibleId;
        this.details = details;
        this.dateEvenement = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public User getUser() {
        return user;
    }

    public String getMatriculeSaisi() {
        return matriculeSaisi;
    }

    public TypeEvenementUser getType() {
        return type;
    }

    public CibleEvenement getCibleType() {
        return cibleType;
    }

    public Long getCibleId() {
        return cibleId;
    }

    public String getDetails() {
        return details;
    }

    public LocalDateTime getDateEvenement() {
        return dateEvenement;
    }
}

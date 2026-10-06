package com.example.demo.entity;

import java.time.LocalDateTime;

import jakarta.persistence.*;

@Entity
@Table(name = "t_comptage_inventaire", uniqueConstraints = @UniqueConstraint(
        name = "uq_comptage_detail_emplacement",
        columnNames = { "detail_journal_id", "emplacement_id" }))
public class ComptageInventaire {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "detail_journal_id", nullable = false)
    private DetailJournal detailJournal;

    @ManyToOne(optional = false)
    @JoinColumn(name = "emplacement_id", nullable = false)
    private Emplacement emplacement;

    @ManyToOne 
    @JoinColumn(name = "user_id")
    User user;

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    @Column(name = "quantite_comptee", nullable = false)
    private Integer quantiteComptee;

    @Column(name = "date_comptage", nullable = false)
    private LocalDateTime dateComptage;

    public ComptageInventaire() {
    }

    public Long getId() {
        return id;
    }

    public DetailJournal getDetailJournal() {
        return detailJournal;
    }

    public Emplacement getEmplacement() {
        return emplacement;
    }

    public Integer getQuantiteComptee() {
        return quantiteComptee;
    }

    public LocalDateTime getDateComptage() {
        return dateComptage;
    }
}

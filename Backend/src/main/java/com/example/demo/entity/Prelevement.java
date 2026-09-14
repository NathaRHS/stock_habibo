package com.example.demo.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;

import org.springframework.cglib.core.Local;

import jakarta.persistence.*;

@Entity
@Table(name = "t_prelevement")
public class Prelevement {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne
    @JoinColumn(name = "commande_id")
    private Commande commande;

    @ManyToOne
    @JoinColumn(name = "emplacement_id")
    private Emplacement emplacement;

    @ManyToOne
    @JoinColumn(name = "statut_prelevement_id", nullable = false)
    private StatutPrelevement statutPrelevement;

    Integer quantitePiecesPrelevee;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "date_prelevement")
    LocalDateTime date;

    @Column(name = "dlc")
    LocalDate dlc;

    @Column(name = "dlv")
    LocalDate dlv;

    public StatutPrelevement getStatutPrelevement() {
        return statutPrelevement;
    }

    public void setStatutPrelevement(StatutPrelevement statutPrelevement) {
        this.statutPrelevement = statutPrelevement;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Commande getCommande() {
        return commande;
    }

    public void setCommande(Commande commande) {
        this.commande = commande;
    }

    public Emplacement getEmplacement() {
        return emplacement;
    }

    public void setEmplacement(Emplacement emplacement) {
        this.emplacement = emplacement;
    }

    public Integer getQuantitePiecesPrelevees() {
        return quantitePiecesPrelevee;
    }

    public void setQuantitePiecesPrelevee(Integer quantitePrelevee) {
        this.quantitePiecesPrelevee = quantitePrelevee;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public LocalDateTime getDate() {
        return date;
    }

    public void setDate(LocalDateTime date) {
        this.date = date;
    }

    public LocalDate getDlc() {
        return dlc;
    }

    public void setDlc(LocalDate dlc) {
        this.dlc = dlc;
    }

    public LocalDate getDlv() {
        return dlv;
    }

    public void setDlv(LocalDate dlv) {
        this.dlv = dlv;
    }
}

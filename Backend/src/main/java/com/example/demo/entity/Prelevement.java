package com.example.demo.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;

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

    /*
     * Facultatif pendant la transition : l'ancien parcours de scan cree encore
     * des prelevements sans ligne de picking.
     */
    @ManyToOne
    @JoinColumn(name = "ligne_picking_id")
    private LignePicking lignePicking;

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

    

    public Prelevement() {
    }

    public Prelevement(Commande commande, LignePicking lignePicking, Emplacement emplacement,
            StatutPrelevement statutPrelevement, Integer quantitePiecesPrelevee, User user, LocalDateTime date,
            LocalDate dlc, LocalDate dlv) {
        this.commande = commande;
        this.lignePicking = lignePicking;
        this.emplacement = emplacement;
        this.statutPrelevement = statutPrelevement;
        this.quantitePiecesPrelevee = quantitePiecesPrelevee;
        this.user = user;
        this.date = date;
        this.dlc = dlc;
        this.dlv = dlv;
    }

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

    public LignePicking getLignePicking() {
        return lignePicking;
    }

    public void setLignePicking(LignePicking lignePicking) {
        this.lignePicking = lignePicking;
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

    public Integer getQuantitePiecesPrelevee() {
        return quantitePiecesPrelevee;
    }
}

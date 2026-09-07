package com.example.demo.entity;

import java.lang.annotation.Repeatable;

import jakarta.persistence.*;

@Entity
@Table(name = "t_commande")
public class Commande {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "journal_mouvement_id")
    private JournalMouvement journalMouvement;

    @ManyToOne
    @JoinColumn(name = "article_id")
    private Article article;

    @Column(name = "etat")
    boolean Etat;

    @Column(name = "remarque", length = 255, nullable = true)
    String remarque;

    @Column(name = "quantite_demande")
    Integer quantiteDemandee;

    @Column(name = "quantite_reel")
    Integer quantiteReel;

    @Column(name = "isChecked")
    private boolean isChecked;

    @ManyToOne
    @JoinColumn(name = "user_id")
    User user;

    public Commande(Article article, boolean etat, String remarque, Integer quantiteDemandee, Integer quantiteReel,
            boolean isChecked, User user) {
        this.article = article;
        Etat = etat;
        this.remarque = remarque;
        this.quantiteDemandee = quantiteDemandee;
        this.quantiteReel = quantiteReel;
        this.isChecked = isChecked;
        this.user = user;
    }

    public Commande() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Article getArticle() {
        return article;
    }

    public void setArticle(Article article) {
        this.article = article;
    }

    public boolean getEtat() {
        return Etat;
    }

    public void setEtat(boolean etat) {
        Etat = etat;
    }

    public String getRemarque() {
        return remarque;
    }

    public void setRemarque(String remarque) {
        this.remarque = remarque;
    }

    public Integer getQuantiteDemandee() {
        return quantiteDemandee;
    }

    public void setQuantiteDemandee(Integer quantiteDemandee) {
        this.quantiteDemandee = quantiteDemandee;
    }

    public Integer getQuantiteReel() {
        return quantiteReel;
    }

    public void setQuantiteReel(Integer quantiteReel) {
        this.quantiteReel = quantiteReel;
    }

    public boolean isChecked() {
        return isChecked;
    }

    public void setChecked(boolean isChecked) {
        this.isChecked = isChecked;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public JournalMouvement getJournalMouvement() {
        return journalMouvement;
    }

    public void setJournalMouvement(JournalMouvement journalMouvement) {
        this.journalMouvement = journalMouvement;
    }

}

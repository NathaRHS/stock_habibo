package com.example.demo.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "t_detail_journal", uniqueConstraints = @UniqueConstraint(name = "uq_detail_journal_article", columnNames = {
        "journal_mouvement_id",
        "article_id",
}))
public class DetailJournal {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "journal_mouvement_id", nullable = false)
    private JournalMouvement journalMouvement;

    @ManyToOne(optional = false)
    @JoinColumn(name = "article_id", nullable = false)
    private Article article;

    @Column(name = "quantite", nullable = false)
    private Integer quantite;

    @Column(name = "quantite_conditionnement")
    private Integer quantiteConditionnement;

    public DetailJournal() {
    }

    public DetailJournal(JournalMouvement journalMouvement, Article article, Integer quantite,
            Integer quantiteConditionnement) {
        this.journalMouvement = journalMouvement;
        this.article = article;
        setQuantite(quantite);
        setQuantiteConditionnement(quantiteConditionnement);
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public JournalMouvement getJournalMouvement() {
        return journalMouvement;
    }

    public void setJournalMouvement(JournalMouvement journalMouvement) {
        this.journalMouvement = journalMouvement;
    }

    public Article getArticle() {
        return article;
    }

    public void setArticle(Article article) {
        this.article = article;
    }

    public Integer getQuantite() {
        return quantite;
    }

    public void setQuantite(Integer quantite) {
        if (quantite == null || quantite <= 0) {
            throw new IllegalArgumentException("La quantite doit etre strictement positive");
        }
        this.quantite = quantite;
    }

    public Integer getQuantiteConditionnement() {
        return quantiteConditionnement;
    }

    public void setQuantiteConditionnement(Integer quantiteConditionnement) {
        if (quantiteConditionnement != null && quantiteConditionnement <= 0) {
            throw new IllegalArgumentException("La quantite de conditionnement doit etre strictement positive");
        }
        this.quantiteConditionnement = quantiteConditionnement;
    }

}

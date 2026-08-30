package com.example.demo.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(name = "t_palette_conditionnement", uniqueConstraints = @UniqueConstraint(
        name = "uk_palette_article_conditionnement",
        columnNames = "article_conditionnement_id"))
public class PaletteConditionnement {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "article_conditionnement_id", nullable = false)
    private ArticleConditionnement articleConditionnement;

    @Column(name = "quantite", nullable = false)
    private Integer quantite;

    public PaletteConditionnement() {
    }

    public PaletteConditionnement(ArticleConditionnement articleConditionnement, Integer quantite) {
        setArticleConditionnement(articleConditionnement);
        setQuantite(quantite);
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public ArticleConditionnement getArticleConditionnement() {
        return articleConditionnement;
    }

    public void setArticleConditionnement(ArticleConditionnement articleConditionnement) {
        if (articleConditionnement == null) {
            throw new IllegalArgumentException("Le conditionnement de l'article est obligatoire");
        }
        this.articleConditionnement = articleConditionnement;
    }

    public Integer getQuantite() {
        return quantite;
    }

    public void setQuantite(Integer quantite) {
        if (quantite == null || quantite <= 0) {
            throw new IllegalArgumentException("La quantite par palette doit etre strictement positive");
        }
        this.quantite = quantite;
    }

}

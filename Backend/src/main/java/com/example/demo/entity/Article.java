package com.example.demo.entity;

import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.*;

@Entity
@Table(name = "t_article")
public class Article {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nom_article", nullable = false)
    private String nomArticle;

    @ManyToOne(optional = false)
    @JoinColumn(name = "type_conditionnement_id", nullable = false)
    private TypeConditionnement typeConditionnement;

    @OneToMany(mappedBy = "article")
    private List<ArticleConditionnement> articleConditionnements = new ArrayList<>();

    @ManyToOne(optional = false)
    @JoinColumn(name = "type_produit_id", nullable = false)
    private TypeProduit typeProduit;

    @Column(name = "code_bar", nullable = false, unique = true)
    private String codeBar;

    @OneToMany(mappedBy = "article")
    private List<DetailJournal> detailsJournal = new ArrayList<>();

    @OneToMany(mappedBy = "article")
    private List<Commande> commandes;

    public Article() {
    }

    public Article(TypeProduit typeProduit, String codeBar, String nomArticle,
            TypeConditionnement typeConditionnement) {
        this.typeProduit = typeProduit;
        this.codeBar = codeBar;
        this.nomArticle = nomArticle;
        this.typeConditionnement = typeConditionnement;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public TypeProduit getTypeProduit() {
        return typeProduit;
    }

    public String getNomArticle() {
        return nomArticle;
    }

    public void setNomArticle(String nomArticle) {
        this.nomArticle = nomArticle;
    }

    public void setTypeProduit(TypeProduit typeProduit) {
        this.typeProduit = typeProduit;
    }

    public String getCodeBar() {
        return codeBar;
    }

    public void setCodeBar(String codeBar) {
        this.codeBar = codeBar;
    }

    public TypeConditionnement getTypeConditionnement() {
        return typeConditionnement;
    }

    public void setTypeConditionnement(TypeConditionnement typeConditionnement) {
        this.typeConditionnement = typeConditionnement;
    }

    public List<ArticleConditionnement> getArticleConditionnements() {
        return articleConditionnements;
    }

    public void setArticleConditionnements(List<ArticleConditionnement> articleConditionnements) {
        this.articleConditionnements = articleConditionnements;
    }

    public List<DetailJournal> getDetailsJournal() {
        return detailsJournal;
    }

    public void setDetailsJournal(List<DetailJournal> detailsJournal) {
        this.detailsJournal = detailsJournal;
    }

}

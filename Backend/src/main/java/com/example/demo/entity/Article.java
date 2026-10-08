package com.example.demo.entity;

import java.math.BigDecimal;
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

    @Column(name = "photo_url")
    private String photoUrl;

    @ManyToOne
    @JoinColumn(name = "famille_id", nullable = true)
    private Famille famille;

    // Contenance d'UNE piece : valeur + unite (ex. 30 cL, 1 L, 350 g). Facultatif.
    @Column(name = "contenance_valeur", precision = 10, scale = 3)
    private BigDecimal contenanceValeur;

    @ManyToOne
    @JoinColumn(name = "unite_id", nullable = true)
    private Unite unite;

    public Famille getFamille() {
        return famille;
    }

    public void setFamille(Famille famille) {
        this.famille = famille;
    }

    public BigDecimal getContenanceValeur() {
        return contenanceValeur;
    }

    public void setContenanceValeur(BigDecimal contenanceValeur) {
        this.contenanceValeur = contenanceValeur;
    }

    public Unite getUnite() {
        return unite;
    }

    public void setUnite(Unite unite) {
        this.unite = unite;
    }

    public String getPhotoUrl() {
        return photoUrl;
    }

    public void setPhotoUrl(String photoUrl) {
        this.photoUrl = photoUrl;
    }

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

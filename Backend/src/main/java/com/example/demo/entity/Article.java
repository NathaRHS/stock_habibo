package com.example.demo.entity;

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
    @JoinColumn(name = "type_produit_id", nullable = false)
    private TypeProduit typeProduit;

    @Column(name = "code_bar", nullable = false, unique = true)
    private String codeBar;

    public Article() {
    }

    public Article(TypeProduit typeProduit, String codeBar, String nomArticle) {
        this.typeProduit = typeProduit;
        this.codeBar = codeBar;
        this.nomArticle = nomArticle;
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

}

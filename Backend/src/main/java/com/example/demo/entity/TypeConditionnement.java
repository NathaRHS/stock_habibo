package com.example.demo.entity;

import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;

@Entity
@Table(name = "t_type_conditionnement")
public class TypeConditionnement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nom_conditionnement", nullable = false, unique = true, length = 100)
    private String nomConditionnement;

    @OneToMany(mappedBy = "typeConditionnement")
    private List<Article> articles = new ArrayList<>();

    @OneToMany(mappedBy = "typeConditionnement")
    private List<ArticleConditionnement> articleConditionnements = new ArrayList<>();

    public List<Article> getArticles() {
        return articles;
    }

    public void setArticles(List<Article> articles) {
        this.articles = articles;
    }

    public List<ArticleConditionnement> getArticleConditionnements() {
        return articleConditionnements;
    }

    public void setArticleConditionnements(List<ArticleConditionnement> articleConditionnements) {
        this.articleConditionnements = articleConditionnements;
    }

    public TypeConditionnement() {
    }

    public TypeConditionnement(String nomConditionnement) {
        this.nomConditionnement = nomConditionnement;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNomConditionnement() {
        return nomConditionnement;
    }

    public void setNomConditionnement(String nomConditionnement) {
        this.nomConditionnement = nomConditionnement;
    }
}

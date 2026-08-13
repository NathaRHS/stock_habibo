package com.example.demo.entity;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "t_type_produit")
public class TypeProduit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nom_type", nullable = false, unique = true)
    private String nomType;

    @OneToMany(mappedBy = "typeProduit")
    private List<Article> articles = new ArrayList<>();

    public TypeProduit() {
    }

    public TypeProduit(String nomType) {
        this.nomType = nomType;
    }

    public TypeProduit(String nomType, List<Article> articles) {
        this.nomType = nomType;
        this.articles = articles;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNomType() {
        return nomType;
    }

    public void setNomType(String nomType) {
        this.nomType = nomType;
    }

    public List<Article> getArticles() {
        return articles;
    }

    public void setArticles(List<Article> articles) {
        this.articles = articles;
    }

}

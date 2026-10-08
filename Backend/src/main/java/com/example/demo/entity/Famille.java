package com.example.demo.entity;

import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.*;

/**
 * Regroupe des articles qui sont des variantes d'un meme produit
 * (par exemple Coca-Cola 30 cL et Coca-Cola 1 L). Une seule ligne par famille.
 */
@Entity
@Table(name = "t_famille")
public class Famille {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nom", nullable = false, unique = true, length = 100)
    private String nom;

    @OneToMany(mappedBy = "famille")
    private List<Article> articles = new ArrayList<>();

    public Famille() {
    }

    public Famille(String nom) {
        this.nom = nom;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public List<Article> getArticles() {
        return articles;
    }

    public void setArticles(List<Article> articles) {
        this.articles = articles;
    }
}

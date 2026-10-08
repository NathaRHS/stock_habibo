package com.example.demo.entity;

import jakarta.persistence.*;

/** Unite de contenance d'un article : g, kg, mL, cL, L... */
@Entity
@Table(name = "t_unite")
public class Unite {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nom_unite", nullable = false, unique = true, length = 20)
    private String nomUnite;

    public Unite() {
    }

    public Unite(String nomUnite) {
        this.nomUnite = nomUnite;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNomUnite() {
        return nomUnite;
    }

    public void setNomUnite(String nomUnite) {
        this.nomUnite = nomUnite;
    }
}

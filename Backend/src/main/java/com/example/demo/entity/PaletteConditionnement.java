package com.example.demo.entity;

import jakarta.persistence.*;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "t_palette_conditionnement")
public class PaletteConditionnement {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Integer id;

    @ManyToOne
    @JoinColumn(name = "t_article_type_conditionnement_id")
    TypeConditionnement typeConditionnement;

    @Column(name = "quantite")
    Integer quantite;

    public PaletteConditionnement(TypeConditionnement typeConditionnement, Integer quantite) {
        this.typeConditionnement = typeConditionnement;
        this.quantite = quantite;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public TypeConditionnement getTypeConditionnement() {
        return typeConditionnement;
    }

    public void setTypeConditionnement(TypeConditionnement typeConditionnement) {
        this.typeConditionnement = typeConditionnement;
    }

    public Integer getQuantite() {
        return quantite;
    }

    public void setQuantite(Integer quantite) {
        this.quantite = quantite;
    }

}

package com.example.demo.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.*;

/** Un reglage de la suggestion d'emplacements (une ligne par cle). */
@Entity
@Table(name = "t_parametre_suggestion")
public class ParametreSuggestion {

    @Id
    @Column(name = "cle", length = 50)
    private String cle;

    @Column(name = "valeur", nullable = false, precision = 10, scale = 3)
    private BigDecimal valeur;

    @Column(name = "description", nullable = false)
    private String description;

    @Column(name = "date_modification", nullable = false)
    private LocalDateTime dateModification;

    public ParametreSuggestion() {
    }

    public ParametreSuggestion(String cle, BigDecimal valeur, String description) {
        this.cle = cle;
        this.valeur = valeur;
        this.description = description;
        this.dateModification = LocalDateTime.now();
    }

    public String getCle() {
        return cle;
    }

    public BigDecimal getValeur() {
        return valeur;
    }

    public void setValeur(BigDecimal valeur) {
        this.valeur = valeur;
        this.dateModification = LocalDateTime.now();
    }

    public String getDescription() {
        return description;
    }

    public LocalDateTime getDateModification() {
        return dateModification;
    }
}

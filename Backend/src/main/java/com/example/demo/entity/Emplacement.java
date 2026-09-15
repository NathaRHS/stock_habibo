package com.example.demo.entity;

import java.util.List;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(name = "t_emplacement", uniqueConstraints = {
        @UniqueConstraint(name = "uk_emplacement_rack_nom", columnNames = {
                "rack_id", "numero_etage", "nom_emplacement" }),
        @UniqueConstraint(name = "uk_emplacement_rack_etage_ordre", columnNames = {
                "rack_id", "numero_etage", "ordre_dans_etage" })
})
public class Emplacement {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nom_emplacement", nullable = false)
    private String nomEmplacement;

    @ManyToOne(optional = false)
    @JoinColumn(name = "rack_id", nullable = false)
    private Rack rack;

    @Column(name = "numero_etage", nullable = false)
    private Integer numeroEtage;

    @Column(name = "ordre_dans_etage")
    private Integer ordreDansEtage;

    @OneToMany(mappedBy = "emplacement")
    private List<Prelevement> prelevements;

    public Emplacement() {
    }

    public Emplacement(
            String nomEmplacement,
            Rack rack,
            Integer numeroEtage,
            Integer ordreDansEtage) {
        this.nomEmplacement = nomEmplacement;
        this.rack = rack;
        this.numeroEtage = numeroEtage;
        this.ordreDansEtage = ordreDansEtage;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNomEmplacement() {
        return nomEmplacement;
    }

    public void setNomEmplacement(String nomEmplacement) {
        this.nomEmplacement = nomEmplacement;
    }

    public Rack getRack() {
        return rack;
    }

    public void setRack(Rack rack) {
        this.rack = rack;
    }

    public Integer getNumeroEtage() {
        return numeroEtage;
    }

    public void setNumeroEtage(Integer numeroEtage) {
        this.numeroEtage = numeroEtage;
    }

    public Integer getOrdreDansEtage() {
        return ordreDansEtage;
    }

    public void setOrdreDansEtage(Integer ordreDansEtage) {
        this.ordreDansEtage = ordreDansEtage;
    }

    public List<Prelevement> getPrelevements() {
        return prelevements;
    }

    public void setPrelevements(List<Prelevement> prelevements) {
        this.prelevements = prelevements;
    }
}

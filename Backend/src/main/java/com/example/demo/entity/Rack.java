package com.example.demo.entity;

import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.*;

@Entity
@Table(name = "t_rack")

public class Rack {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nom_rack", nullable = false, unique = true)
    private String nomRack;

    @Column(name = "nombre_etages", nullable = false)
    private Integer nombreEtages;

    @OneToMany(mappedBy = "rack")
    private List<Emplacement> emplacements = new ArrayList<>();

    public Rack() {
    }

    public Rack(String nomRack, Integer nombreEtages) {
        this.nomRack = nomRack;
        setNombreEtages(nombreEtages);
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNomRack() {
        return nomRack;
    }

    public void setNomRack(String nomRack) {
        this.nomRack = nomRack;
    }

    public Integer getNombreEtages() {
        return nombreEtages;
    }

    public void setNombreEtages(Integer nombreEtages) {
        if (nombreEtages == null || nombreEtages <= 0) {
            throw new IllegalArgumentException("Le nombre d'etages doit etre strictement positif");
        }
        this.nombreEtages = nombreEtages;
    }

    public List<Emplacement> getEmplacements() {
        return emplacements;
    }

    public void setEmplacements(List<Emplacement> emplacements) {
        this.emplacements = emplacements;
    }
}

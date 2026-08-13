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

    @OneToMany(mappedBy = "rack")
    private List<Emplacement> emplacements = new ArrayList<>();

    public Rack() {
    }

    public Rack(String nomRack) {
        this.nomRack = nomRack;
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

    public List<Emplacement> getEmplacements() {
        return emplacements;
    }

    public void setEmplacements(List<Emplacement> emplacements) {
        this.emplacements = emplacements;
    }
}

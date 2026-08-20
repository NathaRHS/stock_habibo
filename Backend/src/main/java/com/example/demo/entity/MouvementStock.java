package com.example.demo.entity;

import java.time.LocalDateTime;

import jakarta.persistence.*;

@Table(name = "t_mouvement_stock")
@Entity
public class MouvementStock {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "type_mouvement_id")
    private TypeMouvementStock typeMouvement;

    @ManyToOne(optional = false)
    @JoinColumn(name = "etage_id", nullable = false)
    private Etage etage;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    @Column(name = "nombre_conditionnements", nullable = false)
    private Integer nombreConditionnements;

    @Column(name = "quantite_pieces_reelle", nullable = false)
    private Integer quantitePiecesReelle;

    @Column(name = "date_mouvement", nullable = false)
    private LocalDateTime dateMouvement;

    @Column(name = "commentaire", length = 500)
    private String commentaire;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public TypeMouvementStock getTypeMouvement() {
        return typeMouvement;
    }

    public void setTypeMouvement(TypeMouvementStock typeMouvement) {
        this.typeMouvement = typeMouvement;
    }

    public Etage getEtage() {
        return etage;
    }

    public void setEtage(Etage etage) {
        this.etage = etage;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public Integer getNombreConditionnements() {
        return nombreConditionnements;
    }

    public void setNombreConditionnements(Integer nombreConditionnements) {
        this.nombreConditionnements = nombreConditionnements;
    }

    public Integer getQuantitePiecesReelle() {
        return quantitePiecesReelle;
    }

    public void setQuantitePiecesReelle(Integer quantitePiecesReelle) {
        this.quantitePiecesReelle = quantitePiecesReelle;
    }

    public LocalDateTime getDateMouvement() {
        return dateMouvement;
    }

    public void setDateMouvement(LocalDateTime dateMouvement) {
        this.dateMouvement = dateMouvement;
    }

    public String getCommentaire() {
        return commentaire;
    }

    public void setCommentaire(String commentaire) {
        this.commentaire = commentaire;
    }

    
}

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
    private TypeMouvement typeMouvement;

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
}

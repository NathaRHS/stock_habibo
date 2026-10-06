package com.example.demo.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

/**
 * Une ligne par changement de statut d'un picking.
 * Une ligne d'historique n'est jamais modifiee : on insere, on ne met pas a jour.
 */
@Entity
@Table(name = "t_historique_picking_statut")
public class HistoriquePickingStatut {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "picking_id", nullable = false)
    private Picking picking;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "statut_id", nullable = false)
    private StatutPicking statut;

    @Column(name = "date_changement", nullable = false)
    private LocalDateTime dateChangement;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    protected HistoriquePickingStatut() {
    }

    public HistoriquePickingStatut(
            Picking picking,
            StatutPicking statut,
            LocalDateTime dateChangement,
            User user) {
        this.picking = picking;
        this.statut = statut;
        this.dateChangement = dateChangement;
        this.user = user;
    }

    public Long getId() {
        return id;
    }

    public Picking getPicking() {
        return picking;
    }

    public StatutPicking getStatut() {
        return statut;
    }

    public LocalDateTime getDateChangement() {
        return dateChangement;
    }

    public User getUser() {
        return user;
    }
}

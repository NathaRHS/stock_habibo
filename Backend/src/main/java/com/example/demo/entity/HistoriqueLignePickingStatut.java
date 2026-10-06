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
 * Une ligne par changement de statut d'une ligne de picking.
 * Une ligne d'historique n'est jamais modifiee : on insere, on ne met pas a jour.
 */
@Entity
@Table(name = "t_historique_ligne_picking_statut")
public class HistoriqueLignePickingStatut {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "ligne_picking_id", nullable = false)
    private LignePicking lignePicking;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "statut_id", nullable = false)
    private StatutLignePicking statut;

    @Column(name = "date_changement", nullable = false)
    private LocalDateTime dateChangement;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    protected HistoriqueLignePickingStatut() {
    }

    public HistoriqueLignePickingStatut(
            LignePicking lignePicking,
            StatutLignePicking statut,
            LocalDateTime dateChangement,
            User user) {
        this.lignePicking = lignePicking;
        this.statut = statut;
        this.dateChangement = dateChangement;
        this.user = user;
    }

    public Long getId() {
        return id;
    }

    public LignePicking getLignePicking() {
        return lignePicking;
    }

    public StatutLignePicking getStatut() {
        return statut;
    }

    public LocalDateTime getDateChangement() {
        return dateChangement;
    }

    public User getUser() {
        return user;
    }
}

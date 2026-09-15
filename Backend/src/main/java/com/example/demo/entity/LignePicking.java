package com.example.demo.entity;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

/**
 * Etape recommandee et quantite reservee dans une tournee de picking.
 */
@Entity
@Table(
        name = "t_ligne_picking",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_ligne_picking_ordre",
                columnNames = { "picking_id", "ordre_passage" }))
public class LignePicking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "picking_id", nullable = false)
    private Picking picking;

    @ManyToOne(optional = false)
    @JoinColumn(name = "commande_id", nullable = false)
    private Commande commande;

    @ManyToOne(optional = false)
    @JoinColumn(name = "emplacement_id", nullable = false)
    private Emplacement emplacement;

    /**
     * Detail de la reception d'origine : il identifie le lot et sa DLC/DLV.
     */
    @ManyToOne(optional = false)
    @JoinColumn(name = "detail_journal_source_id", nullable = false)
    private DetailJournal detailJournalSource;

    @ManyToOne(optional = false)
    @JoinColumn(name = "article_conditionnement_id", nullable = false)
    private ArticleConditionnement articleConditionnement;

    @Column(name = "ordre_passage", nullable = false)
    private Integer ordrePassage;

    @Column(name = "quantite_conditionnements_a_prelever", nullable = false)
    private Integer quantiteConditionnementsAPrelever;

    @Column(name = "quantite_pieces_a_prelever", nullable = false)
    private Integer quantitePiecesAPrelever;

    @Column(name = "date_reservation", nullable = false)
    private LocalDateTime dateReservation;

    @Enumerated(EnumType.STRING)
    @Column(name = "statut", nullable = false, length = 20)
    private StatutLignePicking statut = StatutLignePicking.RESERVEE;

    @OneToMany(mappedBy = "lignePicking")
    private List<Prelevement> prelevements = new ArrayList<>();

    public LignePicking() {
    }

    public LignePicking(
            Commande commande,
            Emplacement emplacement,
            DetailJournal detailJournalSource,
            ArticleConditionnement articleConditionnement,
            Integer ordrePassage,
            Integer quantiteConditionnementsAPrelever,
            Integer quantitePiecesAPrelever) {
        this.commande = commande;
        this.emplacement = emplacement;
        this.detailJournalSource = detailJournalSource;
        this.articleConditionnement = articleConditionnement;
        setOrdrePassage(ordrePassage);
        setQuantiteConditionnementsAPrelever(quantiteConditionnementsAPrelever);
        setQuantitePiecesAPrelever(quantitePiecesAPrelever);
        this.dateReservation = LocalDateTime.now();
        this.statut = StatutLignePicking.RESERVEE;
    }

    @PrePersist
    private void initialiserAvantCreation() {
        if (dateReservation == null) {
            dateReservation = LocalDateTime.now();
        }
        if (statut == null) {
            statut = StatutLignePicking.RESERVEE;
        }
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Picking getPicking() {
        return picking;
    }

    public void setPicking(Picking picking) {
        this.picking = picking;
    }

    public Commande getCommande() {
        return commande;
    }

    public void setCommande(Commande commande) {
        this.commande = commande;
    }

    public Emplacement getEmplacement() {
        return emplacement;
    }

    public void setEmplacement(Emplacement emplacement) {
        this.emplacement = emplacement;
    }

    public DetailJournal getDetailJournalSource() {
        return detailJournalSource;
    }

    public void setDetailJournalSource(DetailJournal detailJournalSource) {
        this.detailJournalSource = detailJournalSource;
    }

    public ArticleConditionnement getArticleConditionnement() {
        return articleConditionnement;
    }

    public void setArticleConditionnement(ArticleConditionnement articleConditionnement) {
        this.articleConditionnement = articleConditionnement;
    }

    public Integer getOrdrePassage() {
        return ordrePassage;
    }

    public void setOrdrePassage(Integer ordrePassage) {
        if (ordrePassage == null || ordrePassage <= 0) {
            throw new IllegalArgumentException("L'ordre de passage doit etre strictement positif");
        }
        this.ordrePassage = ordrePassage;
    }

    public Integer getQuantiteConditionnementsAPrelever() {
        return quantiteConditionnementsAPrelever;
    }

    public void setQuantiteConditionnementsAPrelever(Integer quantiteConditionnementsAPrelever) {
        if (quantiteConditionnementsAPrelever == null || quantiteConditionnementsAPrelever <= 0) {
            throw new IllegalArgumentException("La quantite de conditionnements doit etre strictement positive");
        }
        this.quantiteConditionnementsAPrelever = quantiteConditionnementsAPrelever;
    }

    public Integer getQuantitePiecesAPrelever() {
        return quantitePiecesAPrelever;
    }

    public void setQuantitePiecesAPrelever(Integer quantitePiecesAPrelever) {
        if (quantitePiecesAPrelever == null || quantitePiecesAPrelever <= 0) {
            throw new IllegalArgumentException("La quantite de pieces doit etre strictement positive");
        }
        this.quantitePiecesAPrelever = quantitePiecesAPrelever;
    }

    public LocalDateTime getDateReservation() {
        return dateReservation;
    }

    public void setDateReservation(LocalDateTime dateReservation) {
        this.dateReservation = dateReservation;
    }

    public StatutLignePicking getStatut() {
        return statut;
    }

    public void setStatut(StatutLignePicking statut) {
        this.statut = statut;
    }

    public List<Prelevement> getPrelevements() {
        return prelevements;
    }

    public void setPrelevements(List<Prelevement> prelevements) {
        this.prelevements = prelevements;
    }
}

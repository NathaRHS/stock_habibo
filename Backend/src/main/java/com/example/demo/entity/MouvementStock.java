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

    @ManyToOne
    @JoinColumn(name = "emplacement_id")
    private Emplacement emplacement;

    @Column(name = "en_reserve", nullable = false)
    private boolean enReserve;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    @Column(name = "nombre_conditionnements", nullable = false)
    private Integer nombreConditionnements;

    @ManyToOne(optional = false)
    @JoinColumn(name = "conditionnement_id", nullable = false)
    private ArticleConditionnement articleConditionnement;

    @Column(name = "quantite_pieces_reelle", nullable = false)
    private Integer quantitePiecesReelle;

    @Column(name = "date_mouvement", nullable = false)
    private LocalDateTime dateMouvement;

    @Column(name = "commentaire", length = 500)
    private String commentaire;

    @ManyToOne(optional = false)
    @JoinColumn(name = "detail_journal_id", nullable = false)
    private DetailJournal detailJournal;

    public MouvementStock() {
    }

    public MouvementStock(TypeMouvementStock typeMouvement, Emplacement emplacement, User user,
            Integer nombreConditionnements, ArticleConditionnement articleConditionnement, Integer quantitePiecesReelle,
            LocalDateTime dateMouvement, String commentaire, DetailJournal detailJournal, boolean enReserve) {
        this.typeMouvement = typeMouvement;
        this.emplacement = emplacement;
        this.user = user;
        this.nombreConditionnements = nombreConditionnements;
        this.articleConditionnement = articleConditionnement;
        this.quantitePiecesReelle = quantitePiecesReelle;
        this.dateMouvement = dateMouvement;
        this.commentaire = commentaire;
        this.detailJournal = detailJournal;
        this.enReserve = enReserve;
    }

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

    public Emplacement getEmplacement() {
        return emplacement;
    }

    public void setEmplacement(Emplacement emplacement) {
        this.emplacement = emplacement;
    }

    public boolean isEnReserve() {
        return enReserve;
    }

    public void setEnReserve(boolean enReserve) {
        this.enReserve = enReserve;
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

    public ArticleConditionnement getArticleConditionnement() {
        return articleConditionnement;
    }

    public void setArticleConditionnement(ArticleConditionnement articleConditionnement) {
        this.articleConditionnement = articleConditionnement;
    }

    public DetailJournal getDetailJournal() {
        return detailJournal;
    }

    public void setDetailJournal(DetailJournal detailJournal) {
        this.detailJournal = detailJournal;
    }

}

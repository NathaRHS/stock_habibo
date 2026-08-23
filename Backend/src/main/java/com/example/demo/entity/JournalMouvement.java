package com.example.demo.entity;

import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.*;

@Entity
@Table(name = "t_journal_mouvement")
public class JournalMouvement {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "fournisseur_id")
    private Societe fournisseur;

    @Column(name = "reference", nullable = false, unique = true)
    private String reference;

    @Column(name = "url_piece_jointe")
    private String urlPieceJointe;

    @Column(name = "nom_client")
    private String nomClient;


    @ManyToOne(optional = false)
    @JoinColumn(name = "statut_journal_mouvement_id", nullable = false)
    private StatutjournalMouvement statutJournalMouvement;

    @OneToMany(mappedBy = "journalMouvement", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<DetailJournal> details = new ArrayList<>();

    @ManyToOne(optional = false)
    @JoinColumn(name = "type_mouvement_journal_id", nullable = false)
    private TypeMouvementJournal typeMouvementJournal;

    public JournalMouvement() {
    }

    public JournalMouvement(
            Societe fournisseur,
            String reference,
            String urlPieceJointe,
            String nomClient,
            TypeMouvementJournal typeMouvementJournal,
            StatutjournalMouvement statutJournalMouvement) {
        this.fournisseur = fournisseur;
        this.reference = reference;
        this.urlPieceJointe = urlPieceJointe;
        this.nomClient = nomClient;
        this.typeMouvementJournal = typeMouvementJournal;
        this.statutJournalMouvement = statutJournalMouvement;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Societe getFournisseur() {
        return fournisseur;
    }

    public void setFournisseur(Societe fournisseur) {
        this.fournisseur = fournisseur;
    }

    public String getReference() {
        return reference;
    }

    public void setReference(String reference) {
        this.reference = reference;
    }

    public String getUrlPieceJointe() {
        return urlPieceJointe;
    }

    public void setUrlPieceJointe(String urlPieceJointe) {
        this.urlPieceJointe = urlPieceJointe;
    }

    public String getNomClient() {
        return nomClient;
    }

    public void setNomClient(String nomClient) {
        this.nomClient = nomClient;
    }

    public StatutjournalMouvement getStatutJournalMouvement() {
        return statutJournalMouvement;
    }

    public void setStatutJournalMouvement(StatutjournalMouvement statutJournalMouvement) {
        this.statutJournalMouvement = statutJournalMouvement;
    }

    public List<DetailJournal> getDetails() {
        return details;
    }

    public void setDetails(List<DetailJournal> details) {
        this.details = details;
    }

    public void ajouterDetail(DetailJournal detail) {
        details.add(detail);
        detail.setJournalMouvement(this);
    }

    public void supprimerTousLesDetails() {
        details.clear();
    }

    public TypeMouvementJournal getTypeMouvementJournal() {
        return typeMouvementJournal;
    }

    public void setTypeMouvementJournal(TypeMouvementJournal typeMouvementJournal) {
        this.typeMouvementJournal = typeMouvementJournal;
    }

}

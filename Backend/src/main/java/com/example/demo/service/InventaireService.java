package com.example.demo.service;

import java.util.ArrayList;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.ControleInventaireResponse;
import com.example.demo.dto.LigneControleInventaireResponse;
import com.example.demo.entity.Article;
import com.example.demo.entity.ComptageInventaire;
import com.example.demo.entity.DetailJournal;
import com.example.demo.entity.Emplacement;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.Rack;
import com.example.demo.entity.UserJournalMouvement;
import com.example.demo.repository.ComptageInventaireRepository;
import com.example.demo.repository.EmplacementRepository;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.StockRepository;
import com.example.demo.repository.UserJournalMouvementRepository;

@Service
public class InventaireService {
    private final JournalMouvementRepository journalMouvementRepository;
    private final ComptageInventaireRepository comptageInventaireRepository;
    private final StockRepository stockRepository;
    private final UserJournalMouvementRepository userJournalMouvementRepository;

    public InventaireService(JournalMouvementRepository journalMouvementRepository,
            ComptageInventaireRepository comptageInventaireRepository,
            StockRepository stockRepository, UserJournalMouvementRepository userJournalMouvementRepository) {
        this.journalMouvementRepository = journalMouvementRepository;
        this.comptageInventaireRepository = comptageInventaireRepository;
        this.stockRepository = stockRepository;
        this.userJournalMouvementRepository = userJournalMouvementRepository;
    }

    // fonction pour recuperer l'inventaire global
    public List<LigneControleInventaireResponse> getInventaireLignes(Long journalId) {

        // 1. Vérifier que le journal existe
        JournalMouvement journalMouvement = journalMouvementRepository
                .findById(journalId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Journal mouvement introuvable"));

        // 2. Vérifier qu'il s'agit bien d'un inventaire
        if (!"INVENTAIRE".equalsIgnoreCase(
                journalMouvement.getTypeMouvementJournal().getNomTypeMouvement())) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Ce journal n'est pas un journal d'inventaire");
        }

        // 3. Récupérer tous les comptages effectués dans ce journal
        List<ComptageInventaire> comptages = comptageInventaireRepository
                .findAllByDetailJournalJournalMouvementId(journalId);

        List<LigneControleInventaireResponse> lignes = new ArrayList<>();

        // 4. Construire une ligne de contrôle pour chaque comptage
        for (ComptageInventaire comptage : comptages) {

            DetailJournal detailJournal = comptage.getDetailJournal();
            Article article = detailJournal.getArticle();
            Emplacement emplacement = comptage.getEmplacement();
            Rack rack = emplacement.getRack();

            // Stock que le système pense avoir
            Integer quantiteTheorique = stockRepository.trouverQuantiteTheorique(
                    article.getId(),
                    emplacement.getId());

            // Stock réellement compté par l'opérateur
            Integer quantiteComptee = comptage.getQuantiteComptee();

            // Positif = surplus, négatif = manque
            Integer ecartInteger = quantiteComptee - quantiteTheorique;
            Long ecart = ecartInteger.longValue();

            LigneControleInventaireResponse ligne = new LigneControleInventaireResponse(
                    emplacement.getId(),
                    emplacement.getNomEmplacement(),
                    rack.getNomRack(),
                    emplacement.getNumeroEtage(),
                    article.getId(),
                    article.getNomArticle(),
                    quantiteTheorique,
                    quantiteComptee,
                    ecart);

            lignes.add(ligne);
        }

        return lignes;
    }

    //fonction pour récuperer l'inventaire complet
    public ControleInventaireResponse constructInventaire(Long journalId) {
        List<LigneControleInventaireResponse> ligneControleInventaireResponses = getInventaireLignes(journalId);
        JournalMouvement journal = journalMouvementRepository.findById(journalId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "journal introuvable"));
        List<UserJournalMouvement> userJournalMouvements = userJournalMouvementRepository
                .findAllByJournalMouvementIdOrderByDateDebutAsc(journalId);
        return new ControleInventaireResponse(journalId, journal.getReference(),
                journal.getStatutJournalMouvement().getNomStatut(), userJournalMouvements.size(),
                ligneControleInventaireResponses);

    }


}

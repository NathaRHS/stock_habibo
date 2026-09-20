package com.example.demo.service;

import java.util.ArrayList;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.sortie.ConfirmationSortieResponse;
import com.example.demo.dto.sortie.DetailPrelevementResponse;
import com.example.demo.dto.sortie.JournalSortieResponse;
import com.example.demo.dto.sortie.LigneConfirmationResponse;
import com.example.demo.dto.sortie.OperateurSortieResponse;
import com.example.demo.entity.Commande;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.Picking;
import com.example.demo.entity.Prelevement;
import com.example.demo.entity.User;
import com.example.demo.repository.JournalMouvementRepository;
import com.example.demo.repository.PickingRepository;
import com.example.demo.repository.PrelevementRepository;

@Service
public class ConfirmationSortieService {

    private final JournalMouvementRepository journalMouvementRepository;
    private final PickingRepository pickingRepository;
    private final PrelevementRepository prelevementRepository;

    public ConfirmationSortieService(
            JournalMouvementRepository journalMouvementRepository,
            PickingRepository pickingRepository,
            PrelevementRepository prelevementRepository) {
        this.journalMouvementRepository = journalMouvementRepository;
        this.pickingRepository = pickingRepository;
        this.prelevementRepository = prelevementRepository;
    }

    @Transactional(readOnly = true)
    public ConfirmationSortieResponse obtenirConfirmationSortie(Long journalId) {
        JournalMouvement journal = journalMouvementRepository.findById(journalId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Journal introuvable"));

        if (!"SORTIE".equals(journal.getTypeMouvementJournal().getNomTypeMouvement())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Le journal n'est pas de type sortie");
        }

        Picking picking = pickingRepository.findPicking(journalId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Aucun picking trouve pour ce journal"));

        User operateur = picking.getUser();
        OperateurSortieResponse operateurResponse = new OperateurSortieResponse(
                operateur.getId(),
                operateur.getMatricule(),
                operateur.getUsername());

        List<LigneConfirmationResponse> lignesResponse = new ArrayList<>();

        for (Commande commande : journal.getCommandes()) {
            List<Prelevement> prelevements = prelevementRepository
                    .findAllByCommandeId(commande.getId());

            int quantitePrelevee = 0;
            List<DetailPrelevementResponse> details = new ArrayList<>();

            for (Prelevement prelevement : prelevements) {
                int quantitePreleveePourCeScan = prelevement.getQuantitePiecesPrelevees();

                if (prelevement.getLignePicking() != null
                        && prelevement.getLignePicking().getArticleConditionnement() != null) {
                    int quantitePieceStandard = prelevement.getLignePicking()
                            .getArticleConditionnement()
                            .getQuantitePieceStandard();

                    quantitePreleveePourCeScan = quantitePreleveePourCeScan / quantitePieceStandard;
                }

                quantitePrelevee += quantitePreleveePourCeScan;

                details.add(new DetailPrelevementResponse(
                        prelevement.getId(),
                        prelevement.getEmplacement().getRack().getNomRack(),
                        prelevement.getEmplacement().getNomEmplacement(),
                        quantitePreleveePourCeScan,
                        prelevement.getDlc(),
                        prelevement.getDlv(),
                        prelevement.getDate()));
            }

            int quantiteDemandee = commande.getQuantiteDemandee();
            int ecart = quantitePrelevee - quantiteDemandee;
            String statut;

            if (ecart == 0) {
                statut = "CONFORME";
            } else if (ecart < 0) {
                statut = "MANQUANT";
            } else {
                statut = "EXCEDENT";
            }

            lignesResponse.add(new LigneConfirmationResponse(
                    commande.getId(),
                    commande.getArticle().getNomArticle(),
                    quantiteDemandee,
                    quantitePrelevee,
                    ecart,
                    statut,
                    details));
        }

        JournalSortieResponse journalResponse = new JournalSortieResponse(
                journal.getId(),
                journal.getReference(),
                picking.getDateDebut(),
                picking.getDateFin(),
                journal.getStatutJournalMouvement().getNomStatut());

        return new ConfirmationSortieResponse(
                journalResponse,
                operateurResponse,
                lignesResponse);
    }
}

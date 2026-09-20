package com.example.demo.service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.optimisation.SuggestionEmplacementResponse;
import com.example.demo.dto.optimisation.SuggestionProduitResponse;
import com.example.demo.entity.Article;
import com.example.demo.entity.ArticleConditionnement;
import com.example.demo.entity.DetailJournal;
import com.example.demo.entity.JournalMouvement;
import com.example.demo.entity.StatutLignePicking;
import com.example.demo.objects.EmplacementEvalue;
import com.example.demo.projection.EmplacementCandidatProjection;
import com.example.demo.repository.ArticleConditionnementRepository;
import com.example.demo.repository.DetailJournalRepository;
import com.example.demo.repository.LignePickingRepository;

@Service
public class OptimisationService {

    private final DetailJournalRepository detailJournalRepository;
    private final ArticleConditionnementRepository articleConditionnementRepository;
    private final EmplacementService emplacementService;
    private final LignePickingRepository lignePickingRepository;

    public OptimisationService(
            DetailJournalRepository detailJournalRepository,
            EmplacementService emplacementService,
            ArticleConditionnementRepository articleConditionnementRepository,
            LignePickingRepository lignePickingRepository) {
        this.detailJournalRepository = detailJournalRepository;
        this.articleConditionnementRepository = articleConditionnementRepository;
        this.emplacementService = emplacementService;
        this.lignePickingRepository = lignePickingRepository;
    }

    public SuggestionProduitResponse proposerEmplacements(Long detailJournalId) {

        if (detailJournalId == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "L'identifiant du detail journal est obligatoire");
        }

        DetailJournal detailJournal = detailJournalRepository.findById(detailJournalId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Le detail journal est introuvable"));

        JournalMouvement journal = detailJournal.getJournalMouvement();
        if (journal == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Le detail n'est associe a aucun journal");
        }

        if (!"ENTREE".equalsIgnoreCase(
                journal.getTypeMouvementJournal().getNomTypeMouvement())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Le journal n'est pas de type ENTREE");
        }

        String statutJournal = journal.getStatutJournalMouvement().getNomStatut();
        if (!"VALIDE".equalsIgnoreCase(statutJournal)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Le journal doit etre valide avant de proposer une affectation");
        }

        Article article = detailJournal.getArticle();
        if (article == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Aucun article n'est associe a ce detail journal");
        }

        ArticleConditionnement articleConditionnement = articleConditionnementRepository
                .findFirstByArticleIdOrderByIdAsc(article.getId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Aucun conditionnement n'est configure pour cet article"));

        Integer quantitePieceStandard = articleConditionnement.getQuantitePieceStandard();
        if (quantitePieceStandard == null || quantitePieceStandard <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Le conditionnement possede une quantite standard invalide");
        }

        Integer quantiteAAffecter = detailJournal.getQuantiteConditionnement();
        if (quantiteAAffecter == null || quantiteAAffecter <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La quantite de conditionnements a affecter est invalide");
        }

        List<EmplacementCandidatProjection> emplacementsPossibles = emplacementService
                .trouverEmplacementLibre(articleConditionnement.getId());

        List<EmplacementCandidatProjection> emplacementsCandidats = filtrerEmplacementsCandidats(
                emplacementsPossibles,
                article.getId());

        List<EmplacementEvalue> emplacementsEvalues = calculerScores(
                emplacementsCandidats,
                article.getId(),
                quantiteAAffecter);

        emplacementsEvalues.sort(
                Comparator.comparingDouble(EmplacementEvalue::getScoreFinal).reversed());

        long quantiteRestante = repartirQuantite(
                emplacementsEvalues,
                quantiteAAffecter);

        List<SuggestionEmplacementResponse> suggestions = emplacementsEvalues.stream()
                .filter(evalue -> evalue.getQuantiteConditionnementsProposee() != null
                        && evalue.getQuantiteConditionnementsProposee() > 0)
                .map(this::creerSuggestionEmplacementResponse)
                .toList();

        long quantiteProposee = (long) quantiteAAffecter - quantiteRestante;

        return new SuggestionProduitResponse(
                detailJournal.getId(),
                article.getId(),
                article.getNomArticle(),
                articleConditionnement.getId(),
                quantiteAAffecter,
                quantiteProposee,
                quantiteRestante,
                suggestions);
    }

    private List<EmplacementEvalue> calculerScores(
            List<EmplacementCandidatProjection> candidats,
            Long articleAPlacerId,
            long quantiteAAffecter) {

        List<EmplacementEvalue> emplacementsEvalues = new ArrayList<>();
        if (candidats.isEmpty()) {
            return emplacementsEvalues;
        }

        long positionMin = calculerPosition(candidats.get(0));
        long positionMax = calculerPosition(candidats.get(0));

        for (EmplacementCandidatProjection candidat : candidats) {
            long position = calculerPosition(candidat);

            if (position < positionMin) {
                positionMin = position;
            }

            if (position > positionMax) {
                positionMax = position;
            }
        }

        for (EmplacementCandidatProjection candidat : candidats) {
            EmplacementEvalue evalue = creerEmplacementEvalue(candidat);

            long capaciteLibre = calculerCapaciteLibre(candidat);
            long position = calculerPosition(candidat);

            double scoreProximite = calculerScoreProximite(
                    position,
                    positionMin,
                    positionMax);
            double scoreCapacite = calculerScoreCapacite(
                    capaciteLibre,
                    quantiteAAffecter);
            double scoreRegroupement = calculerScoreRegroupement(
                    candidat.getArticlePresentId(),
                    articleAPlacerId);

            // Les anomalies ne sont pas encore disponibles dans la projection.
            double scoreFiabilite = calculerScoreFiabilite(0);

            double scoreFinal = calculerScoreFinal(
                    scoreProximite,
                    scoreCapacite,
                    scoreFiabilite,
                    scoreRegroupement);

            evalue.setCapaciteLibre(capaciteLibre);
            evalue.setScoreProximite(scoreProximite);
            evalue.setScoreCapacite(scoreCapacite);
            evalue.setScoreFiabilite(scoreFiabilite);
            evalue.setScoreRegroupement(scoreRegroupement);
            evalue.setScoreFinal(scoreFinal);

            evalue.getRaisons().add(
                    "Capacite libre : " + capaciteLibre + " conditionnement(s)");

            if (candidat.getArticlePresentId() == null) {
                evalue.getRaisons().add("Emplacement vide disponible");
            } else {
                evalue.getRaisons().add(
                        "L'article est deja present dans cet emplacement");
            }

            emplacementsEvalues.add(evalue);
        }

        return emplacementsEvalues;
    }

    private EmplacementEvalue creerEmplacementEvalue(
            EmplacementCandidatProjection candidat) {

        EmplacementEvalue evalue = new EmplacementEvalue();

        evalue.setEmplacementId(candidat.getEmplacementId());
        evalue.setNomEmplacement(candidat.getNomEmplacement());
        evalue.setRackId(candidat.getRackId());
        evalue.setNomRack(candidat.getNomRack());
        evalue.setOrdreRack(candidat.getOrdreRack());
        evalue.setNumeroEtage(candidat.getNumeroEtage());
        evalue.setOrdreDansEtage(candidat.getOrdreDansEtage());
        evalue.setArticlePresentId(candidat.getArticlePresentId());
        evalue.setQuantitePiecesPresentes(candidat.getQuantitePiecesPresentes());
        evalue.setConditionnementsPresents(calculerConditionnementsPresents(candidat));
        evalue.setCapaciteMaxConditionnements(
                candidat.getCapaciteMaxConditionnements());

        return evalue;
    }

    private long calculerCapaciteLibre(
            EmplacementCandidatProjection candidat) {

        Integer capaciteMax = candidat.getCapaciteMaxConditionnements();
        if (capaciteMax == null || capaciteMax <= 0) {
            return 0;
        }

        long capaciteLibre = capaciteMax - calculerConditionnementsPresents(candidat);
        return Math.max(capaciteLibre, 0);
    }

    private long calculerConditionnementsPresents(
            EmplacementCandidatProjection candidat) {

        Long quantitePiecesPresentes = candidat.getQuantitePiecesPresentes();
        Integer quantitePieceStandard = candidat.getQuantitePieceStandard();

        if (quantitePiecesPresentes == null) {
            quantitePiecesPresentes = 0L;
        }

        if (quantitePieceStandard == null || quantitePieceStandard <= 0) {
            return 0;
        }

        return (quantitePiecesPresentes + quantitePieceStandard - 1L)
                / quantitePieceStandard;
    }

    private double calculerScoreCapacite(
            long capaciteLibre,
            long quantiteAAffecter) {

        if (capaciteLibre <= 0 || quantiteAAffecter <= 0) {
            return 0;
        }

        if (capaciteLibre >= quantiteAAffecter) {
            return 100;
        }

        return 100.0 * capaciteLibre / quantiteAAffecter;
    }

    private double calculerScoreFiabilite(long nombreAnomalies) {

        double score = 100 - (nombreAnomalies * 10);
        return Math.max(score, 0);
    }

    private double calculerScoreRegroupement(
            Long articlePresentId,
            Long articleAPlacerId) {

        if (articlePresentId == null) {
            return 60;
        }

        if (articlePresentId.equals(articleAPlacerId)) {
            return 100;
        }

        return 0;
    }

    private double calculerScoreFinal(
            double scoreProximite,
            double scoreCapacite,
            double scoreFiabilite,
            double scoreRegroupement) {

        return scoreProximite * 0.25
                + scoreCapacite * 0.30
                + scoreFiabilite * 0.30
                + scoreRegroupement * 0.15;
    }

    private long calculerPosition(
            EmplacementCandidatProjection candidat) {

        if (candidat.getOrdreRack() == null
                || candidat.getNumeroEtage() == null
                || candidat.getOrdreDansEtage() == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "L'ordre physique de l'emplacement "
                            + candidat.getNomEmplacement()
                            + " doit etre renseigne pour calculer une suggestion");
        }

        return candidat.getOrdreRack() * 1000L
                + candidat.getNumeroEtage() * 100L
                + candidat.getOrdreDansEtage();
    }

    private double calculerScoreProximite(
            long positionCandidat,
            long positionMin,
            long positionMax) {

        if (positionMin == positionMax) {
            return 100;
        }

        return 100.0 * (positionMax - positionCandidat)
                / (positionMax - positionMin);
    }

    private List<EmplacementCandidatProjection> filtrerEmplacementsCandidats(
            List<EmplacementCandidatProjection> emplacementsPossibles,
            Long articleId) {

        List<EmplacementCandidatProjection> emplacementsCandidats = new ArrayList<>();

        if (emplacementsPossibles == null || emplacementsPossibles.isEmpty()) {
            return emplacementsCandidats;
        }

        List<Long> emplacementIds = emplacementsPossibles.stream()
                .map(EmplacementCandidatProjection::getEmplacementId)
                .filter(id -> id != null)
                .toList();

        List<StatutLignePicking> statutsActifs = List.of(
                StatutLignePicking.RESERVEE,
                StatutLignePicking.EN_COURS);

        Set<Long> emplacementIdsAvecPickingActif = new HashSet<>(
                lignePickingRepository.findEmplacementIdsAvecPickingActif(
                        emplacementIds,
                        statutsActifs));

        for (EmplacementCandidatProjection emplacement : emplacementsPossibles) {
            if (emplacement.getEmplacementId() == null) {
                continue;
            }

            Long articlePresentId = emplacement.getArticlePresentId();
            if (articlePresentId != null && !articlePresentId.equals(articleId)) {
                continue;
            }

            if (emplacementIdsAvecPickingActif.contains(emplacement.getEmplacementId())) {
                continue;
            }

            if (calculerCapaciteLibre(emplacement) <= 0) {
                continue;
            }

            emplacementsCandidats.add(emplacement);
        }

        return emplacementsCandidats;
    }

    private long repartirQuantite(
            List<EmplacementEvalue> emplacementsEvalues,
            long quantiteAAffecter) {

        long quantiteRestante = quantiteAAffecter;

        for (EmplacementEvalue evalue : emplacementsEvalues) {
            long quantiteProposee = Math.min(
                    evalue.getCapaciteLibre(),
                    quantiteRestante);

            evalue.setQuantiteConditionnementsProposee(quantiteProposee);
            quantiteRestante -= quantiteProposee;

            if (quantiteRestante == 0) {
                break;
            }
        }

        return quantiteRestante;
    }

    private SuggestionEmplacementResponse creerSuggestionEmplacementResponse(
            EmplacementEvalue evalue) {

        return new SuggestionEmplacementResponse(
                evalue.getEmplacementId(),
                evalue.getNomEmplacement(),
                evalue.getRackId(),
                evalue.getNomRack(),
                evalue.getOrdreRack(),
                evalue.getNumeroEtage(),
                evalue.getOrdreDansEtage(),
                evalue.getCapaciteLibre(),
                evalue.getQuantiteConditionnementsProposee(),
                evalue.getScoreProximite(),
                evalue.getScoreCapacite(),
                evalue.getScoreFiabilite(),
                evalue.getScoreRegroupement(),
                evalue.getScoreFinal(),
                evalue.getRaisons());
    }
}

package com.example.demo.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.LignePickingCreateRequest;
import com.example.demo.dto.LignePickingResponse;
import com.example.demo.dto.ScanLigneRequest;
import com.example.demo.dto.ScanLigneResponse;
import com.example.demo.entity.ArticleConditionnement;
import com.example.demo.entity.Commande;
import com.example.demo.entity.DetailJournal;
import com.example.demo.entity.Emplacement;
import com.example.demo.entity.LignePicking;
import com.example.demo.entity.Picking;
import com.example.demo.entity.Prelevement;
import com.example.demo.entity.StatutLignePicking;
import com.example.demo.entity.StatutPicking;
import com.example.demo.entity.StatutPrelevement;
import com.example.demo.repository.ArticleConditionnementRepository;
import com.example.demo.repository.CommandeRepository;
import com.example.demo.repository.DetailJournalRepository;
import com.example.demo.repository.EmplacementRepository;
import com.example.demo.repository.LignePickingRepository;
import com.example.demo.repository.MouvementStockRepository;
import com.example.demo.repository.PickingRepository;
import com.example.demo.repository.PrelevementRepository;
import com.example.demo.repository.StatutPrelevementRepository;
import com.example.demo.repository.StockRepository;

@Service
public class LignePickingService {

        private final LignePickingRepository lignePickingRepository;
        private final PickingRepository pickingRepository;
        private final CommandeRepository commandeRepository;
        private final EmplacementRepository emplacementRepository;
        private final DetailJournalRepository detailJournalRepository;
        private final ArticleConditionnementRepository articleConditionnementRepository;
        private final MouvementStockRepository mouvementStockRepository;
        private final StockRepository stockRepository;
        private final StatutPrelevementRepository statutPrelevementRepository;
        private final PrelevementRepository prelevementRepository;

        public LignePickingService(
                        LignePickingRepository lignePickingRepository,
                        PickingRepository pickingRepository,
                        PrelevementRepository prelevementRepository,
                        CommandeRepository commandeRepository,
                        EmplacementRepository emplacementRepository,
                        DetailJournalRepository detailJournalRepository,
                        ArticleConditionnementRepository articleConditionnementRepository,
                        MouvementStockRepository mouvementStockRepository,
                        StatutPrelevementRepository statutPrelevementRepository,
                        StockRepository stockRepository) {
                this.lignePickingRepository = lignePickingRepository;
                this.pickingRepository = pickingRepository;
                this.commandeRepository = commandeRepository;
                this.emplacementRepository = emplacementRepository;
                this.detailJournalRepository = detailJournalRepository;
                this.articleConditionnementRepository = articleConditionnementRepository;
                this.mouvementStockRepository = mouvementStockRepository;
                this.stockRepository = stockRepository;
                this.statutPrelevementRepository = statutPrelevementRepository;
                this.prelevementRepository = prelevementRepository;
        }

        @Transactional
        public LignePickingResponse creerLigne(LignePickingCreateRequest request) {

                // 1. Verification des informations recues.
                if (request == null) {
                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "Les informations de la ligne sont obligatoires");
                }

                if (request.pickingId() == null
                                || request.commandeId() == null
                                || request.emplacementId() == null
                                || request.articleConditionnementId() == null) {
                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "Tous les identifiants de la ligne sont obligatoires");
                }

                if (request.ordrePassage() == null || request.ordrePassage() <= 0) {
                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "L'ordre de passage doit etre strictement positif");
                }

                if (request.quantiteConditionnementsAPrelever() == null
                                || request.quantiteConditionnementsAPrelever() <= 0) {
                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "La quantite a prelever doit etre strictement positive");
                }

                // 2. Recuperation des objets correspondants aux identifiants.
                Picking picking = pickingRepository.findById(request.pickingId())
                                .orElseThrow(() -> new ResponseStatusException(
                                                HttpStatus.NOT_FOUND,
                                                "Picking introuvable"));

                Commande commande = commandeRepository.findById(request.commandeId())
                                .orElseThrow(() -> new ResponseStatusException(
                                                HttpStatus.NOT_FOUND,
                                                "Commande introuvable"));

                Emplacement emplacement = emplacementRepository.findById(request.emplacementId())
                                .orElseThrow(() -> new ResponseStatusException(
                                                HttpStatus.NOT_FOUND,
                                                "Emplacement introuvable"));

                DetailJournal detailJournalSource = detailJournalRepository
                                .findByArticleIdAndDlcAndDlv(
                                                commande.getArticle().getId(),
                                                request.dlc(),
                                                request.dlv())
                                .orElseThrow(() -> new ResponseStatusException(
                                                HttpStatus.NOT_FOUND,
                                                "Aucun lot ne correspond a cet article, cette DLC et cette DLV"));

                ArticleConditionnement articleConditionnement = articleConditionnementRepository
                                .findById(request.articleConditionnementId())
                                .orElseThrow(() -> new ResponseStatusException(
                                                HttpStatus.NOT_FOUND,
                                                "Conditionnement introuvable"));

                // 3. Le picking doit encore accepter des reservations.
                if (picking.getStatut() == StatutPicking.TERMINE
                                || picking.getStatut() == StatutPicking.ANNULE) {
                        throw new ResponseStatusException(
                                        HttpStatus.CONFLICT,
                                        "Impossible d'ajouter une ligne a un picking termine ou annule");
                }

                // 4. Une position du parcours ne peut etre utilisee qu'une seule fois.
                if (lignePickingRepository.existsByPickingIdAndOrdrePassage(
                                picking.getId(),
                                request.ordrePassage())) {
                        throw new ResponseStatusException(
                                        HttpStatus.CONFLICT,
                                        "Cet ordre de passage est deja utilise dans le picking");
                }

                // 5. La commande doit appartenir au journal concerne par le picking.
                if (!commande.getJournalMouvement().getId()
                                .equals(picking.getJournalMouvement().getId())) {
                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "La commande n'appartient pas au journal du picking");
                }

                // 6. Le lot et le conditionnement doivent correspondre a l'article commande.
                if (!detailJournalSource.getArticle().getId()
                                .equals(commande.getArticle().getId())) {
                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "Le lot source ne correspond pas a l'article commande");
                }

                if (!"ENTREE".equalsIgnoreCase(
                                detailJournalSource.getJournalMouvement()
                                                .getTypeMouvementJournal()
                                                .getNomTypeMouvement())) {
                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "Le lot source doit provenir d'un journal d'entree");
                }

                if (!articleConditionnement.getArticle().getId()
                                .equals(commande.getArticle().getId())) {
                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "Le conditionnement ne correspond pas a l'article commande");
                }

                // 7. Le lot choisi doit avoir ete range dans l'emplacement recommande.
                if (!mouvementStockRepository.existsByDetailJournalIdAndEmplacementId(
                                detailJournalSource.getId(),
                                emplacement.getId())) {
                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "Le lot source n'est pas present dans cet emplacement");
                }

                // 8. Conversion de la quantite demandee en pieces.
                if (articleConditionnement.getQuantitePieceStandard() == null
                                || articleConditionnement.getQuantitePieceStandard() <= 0) {
                        throw new ResponseStatusException(
                                        HttpStatus.CONFLICT,
                                        "La quantite standard du conditionnement est invalide");
                }

                Integer quantitePiecesAPrelever;
                try {
                        quantitePiecesAPrelever = Math.multiplyExact(
                                        request.quantiteConditionnementsAPrelever(),
                                        articleConditionnement.getQuantitePieceStandard());
                } catch (ArithmeticException exception) {
                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "La quantite en pieces est trop grande");
                }

                // 9. La somme des lignes ne doit pas depasser la commande.
                int quantiteConditionnementsDejaAllouee = 0;
                List<LignePicking> lignesCommande = lignePickingRepository
                                .findAllByCommandeId(commande.getId());

                for (LignePicking ligneExistante : lignesCommande) {
                        if (ligneExistante.getStatut() != StatutLignePicking.ANNULEE
                                        && ligneExistante.getStatut() != StatutLignePicking.IMPOSSIBLE) {
                                quantiteConditionnementsDejaAllouee += ligneExistante
                                                .getQuantiteConditionnementsAPrelever();
                        }
                }

                int quantiteConditionnementsApresAjout = quantiteConditionnementsDejaAllouee
                                + request.quantiteConditionnementsAPrelever();

                if (commande.getQuantiteDemandee() == null || commande.getQuantiteDemandee() <= 0) {
                        throw new ResponseStatusException(
                                        HttpStatus.CONFLICT,
                                        "La commande possede une quantite demandee invalide");
                }

                if (quantiteConditionnementsApresAjout > commande.getQuantiteDemandee()) {
                        throw new ResponseStatusException(
                                        HttpStatus.CONFLICT,
                                        "La quantite totale des lignes depasserait la quantite commandee");
                }

                // 10. Verification du stock restant apres les autres reservations.
                Integer stockPhysiqueEnPieces = stockRepository.trouverQuantiteTheorique(
                                commande.getArticle().getId(),
                                emplacement.getId());

                if (stockPhysiqueEnPieces == null) {
                        stockPhysiqueEnPieces = 0;
                }

                int quantitePiecesDejaReservee = 0;
                List<LignePicking> lignesDejaPlacees = lignePickingRepository
                                .findAllByEmplacementIdAndCommandeArticleId(
                                                emplacement.getId(),
                                                commande.getArticle().getId());

                for (LignePicking ligneExistante : lignesDejaPlacees) {
                        if (ligneExistante.getStatut() == StatutLignePicking.RESERVEE
                                        || ligneExistante.getStatut() == StatutLignePicking.EN_COURS) {
                                quantitePiecesDejaReservee += ligneExistante.getQuantitePiecesAPrelever();
                        }
                }

                int stockDisponibleEnPieces = stockPhysiqueEnPieces - quantitePiecesDejaReservee;

                if (quantitePiecesAPrelever > stockDisponibleEnPieces) {
                        throw new ResponseStatusException(
                                        HttpStatus.CONFLICT,
                                        "Stock disponible insuffisant dans cet emplacement");
                }

                // 11. Toutes les verifications sont passees : la reservation est creee.
                LignePicking lignePicking = new LignePicking(
                                commande,
                                emplacement,
                                detailJournalSource,
                                articleConditionnement,
                                request.ordrePassage(),
                                request.quantiteConditionnementsAPrelever(),
                                quantitePiecesAPrelever);

                lignePicking.setPicking(picking);

                LignePicking ligneSauvegardee = lignePickingRepository.save(lignePicking);

                return new LignePickingResponse(
                                ligneSauvegardee.getId(),
                                picking.getId(),
                                commande.getId(),
                                commande.getArticle().getNomArticle(),
                                emplacement.getId(),
                                emplacement.getNomEmplacement(),
                                detailJournalSource.getDlc(),
                                detailJournalSource.getDlv(),
                                articleConditionnement.getId(),
                                ligneSauvegardee.getOrdrePassage(),
                                ligneSauvegardee.getQuantiteConditionnementsAPrelever(),
                                ligneSauvegardee.getQuantitePiecesAPrelever(),
                                ligneSauvegardee.getStatut());
        }

        public ScanLigneResponse scan(ScanLigneRequest scanLigneRequest) {
                if (scanLigneRequest == null) {
                        throw new ResponseStatusException(HttpStatus.NOT_FOUND, "la requete est vide");
                }

                LignePicking lignePicking = lignePickingRepository.findById(scanLigneRequest.lignePickingId())
                                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                                                "ligne introuvable"));

                if (lignePicking.getStatut() != StatutLignePicking.RESERVEE
                                && lignePicking.getStatut() != StatutLignePicking.EN_COURS) {

                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "Cette ligne n'est plus disponible pour le prelevement");
                }

                ArticleConditionnement articleConditionnement = articleConditionnementRepository
                                .findByCodeBarres(scanLigneRequest.codeBarres())
                                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                                                "conditionnement introuvable !"));

                if (lignePicking.getArticleConditionnement().getId() != articleConditionnement.getId()) {
                        throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                                        "l'article conditionnement n'appartient pas à la ligne -> "
                                                        + lignePicking.getId());
                }

                DetailJournal detailJournal = detailJournalRepository
                                .findByArticleIdAndDlcAndDlv(articleConditionnement.getArticle().getId(),
                                                scanLigneRequest.dlc(), scanLigneRequest.dlv())
                                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                                                "le detail journal contenant cette article n'existe pas"));

                if (detailJournal.getId() != lignePicking.getId()) {
                        throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                                        "le detail journal n'est pas dans la ligne");
                }

                StatutPrelevement statutPrelevement = statutPrelevementRepository.findByNomStatut("CONFIRME")
                                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                                                "statut confirmé introuvable"));

                // Prelevement prelevement = new Prelevement(lignePicking.getCommande(), lignePicking,
                //                 lignePicking.getEmplacement(), statutPrelevement,
                //                 scanLigneRequest.quantiteConditionnement(), lignePicking.getPicking().getUser(),
                //                 LocalDateTime.now(), scanLigneRequest.dlc(), scanLigneRequest.dlv());

                int quantitePiecesScannee = Math.multiplyExact(
                                scanLigneRequest.quantiteConditionnement(),
                                lignePicking.getArticleConditionnement().getQuantitePieceStandard());

                List<Prelevement> prelevementsSurCetteLigne = prelevementRepository
                                .findAllByLignePickingId(lignePicking.getId());

                int quantitePiecesPreleveesAvant = 0;

                for (Prelevement prelevementExistant : prelevementsSurCetteLigne) {
                        quantitePiecesPreleveesAvant += prelevementExistant.getQuantitePiecesPrelevees();
                }

                int quantitePiecesPreleveesApres = quantitePiecesPreleveesAvant + quantitePiecesScannee;

                if (quantitePiecesPreleveesApres > lignePicking.getQuantitePiecesAPrelever()) {

                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "La quantite scannee depasse la quantite prevue");
                }

                Prelevement prelevementCree = new Prelevement(
                                lignePicking.getCommande(),
                                lignePicking,
                                lignePicking.getEmplacement(),
                                statutPrelevement,
                                quantitePiecesScannee,
                                lignePicking.getPicking().getUser(),
                                LocalDateTime.now(),
                                lignePicking.getDetailJournalSource().getDlc(),
                                lignePicking.getDetailJournalSource().getDlv());

                Prelevement prelevementSauvegarde = prelevementRepository.save(prelevementCree);

                int quantitePiecesRestante = lignePicking.getQuantitePiecesAPrelever()
                                - quantitePiecesPreleveesApres;

                boolean ligneTerminee = quantitePiecesRestante == 0;

                if (ligneTerminee) {
                        lignePicking.setStatut(StatutLignePicking.PRELEVEE);
                } else {
                        lignePicking.setStatut(StatutLignePicking.EN_COURS);
                }

                lignePickingRepository.save(lignePicking);

                Integer quantitePieceStandard = lignePicking.getArticleConditionnement().getQuantitePieceStandard();

                return new ScanLigneResponse(
                                prelevementSauvegarde.getId(),
                                lignePicking.getId(),
                                scanLigneRequest.quantiteConditionnement(),
                                quantitePiecesPreleveesApres / quantitePieceStandard,
                                quantitePiecesRestante / quantitePieceStandard,
                                ligneTerminee);

        }
}

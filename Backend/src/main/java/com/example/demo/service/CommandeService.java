package com.example.demo.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.commande.AjoutCommandeRequest;
import com.example.demo.dto.commande.CommandeCreateRequest;
import com.example.demo.dto.commande.CommandeResponse;
import com.example.demo.dto.commande.CommandeResponseAll;
import com.example.demo.dto.picking.LignePickingCreateRequest;
import com.example.demo.dto.picking.LignePickingResponse;
import com.example.demo.dto.picking.MeilleurEmplacementResponse;
import com.example.demo.dto.stock.PrelevementResponse;
import com.example.demo.repository.*;

import com.example.demo.entity.*;
import com.example.demo.projection.StockProjection;

@Service
public class CommandeService {

        // VARIABLES
        private final String STATUT_PRELEVE = "PRELEVE";

        private final JournalMouvementRepository journalMouvementRepository;
        private final ArticleRepository articleRepository;
        private final CommandeRepository commandeRepository;
        private final EmplacementRepository emplacementRepository;
        private final MouvementStockRepository mouvementStockRepository;
        private final DetailJournalRepository detailJournalRepository;
        private final PrelevementRepository prelevementRepository;
        private final StatuPrelevementRepository statuPrelevementRepository;
        private final UserRepository userRepository;
        private final StockRepository stockRepository;
        private final LignePickingService lignePickingService;
        private final RackRepository rackRepository;
        private final ArticleConditionnementRepository articleConditionnementRepository;
        private final PickingRepository pickingRepository;

        public CommandeService(JournalMouvementRepository journalMouvementRepository,
                        LignePickingService lignePickingService,
                        RackRepository rackRepository,
                        ArticleRepository articleRepository,
                        EmplacementRepository emplacementRepository, MouvementStockRepository mouvementStockRepository,
                        CommandeRepository commandeRepository, DetailJournalRepository detailJournalRepository,
                        PrelevementRepository prelevementRepository,
                        ArticleConditionnementRepository articleConditionnementRepository,
                        PickingRepository pickingRepository,
                        StatuPrelevementRepository statuPrelevementRepository,
                        UserRepository userRepository, StockRepository stockRepository) {
                this.journalMouvementRepository = journalMouvementRepository;
                this.articleRepository = articleRepository;
                this.commandeRepository = commandeRepository;
                this.emplacementRepository = emplacementRepository;
                this.mouvementStockRepository = mouvementStockRepository;
                this.detailJournalRepository = detailJournalRepository;
                this.prelevementRepository = prelevementRepository;
                this.statuPrelevementRepository = statuPrelevementRepository;
                this.userRepository = userRepository;
                this.stockRepository = stockRepository;
                this.lignePickingService = lignePickingService;
                this.rackRepository = rackRepository;
                this.articleConditionnementRepository = articleConditionnementRepository;
                this.pickingRepository = pickingRepository;
        }

        @Transactional
        public CommandeResponseAll InsertAllCommande(List<CommandeCreateRequest> commandes, Long idJournal) {
                List<Commande> commandeAInserer = new ArrayList<>();
                for (CommandeCreateRequest commande : commandes) {
                        JournalMouvement journal = journalMouvementRepository.findById(idJournal).orElseThrow(
                                        () -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                                                        "Journal de la commande introuvable"));
                        if (!journal.getTypeMouvementJournal().getNomTypeMouvement().equals("SORTIE")) {
                                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                                                "Cette session n'est pas une session de sortie");
                        }

                        if (commande == null) {
                                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La commande est null");
                        }
                        Article article = articleRepository.findById(commande.idArticle())
                                        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                                                        "article introuvable"));

                        Commande newCommande = new Commande();
                        newCommande.setArticle(article);
                        newCommande.setJournalMouvement(journal);
                        newCommande.setQuantiteDemandee(commande.quantiteDemande());
                        commandeAInserer.add(newCommande);

                }
                List<Commande> commandeValiny = commandeRepository.saveAll(commandeAInserer);
                List<CommandeResponse> responses = new ArrayList<>();

                for (Commande commandeSauvegardee : commandeValiny) {
                        CommandeResponse response = new CommandeResponse(
                                        commandeSauvegardee.getId(),
                                        commandeSauvegardee.getJournalMouvement().getId(),
                                        commandeSauvegardee.getArticle().getId(),
                                        commandeSauvegardee.getArticle().getNomArticle(),
                                        commandeSauvegardee.getQuantiteDemandee());

                        responses.add(response);
                }

                return new CommandeResponseAll(responses);

        }

        // public CommandeResponse versResponse(Commande commande){
        // CommandeResponse commandeResponse = new
        // CommandeResponse(commande.getJournalMouvement().getId(),commande.getArticle().getNomArticle(),commande.getArticle().getId(),commande.getRemarque(),commande.getQuantiteDemandee(),commande.getQuantiteReel(),commande.getUser().getMatricule(),commande.getEtat());
        // }

        public CommandeResponseAll getAll(Long journalId) {
                JournalMouvement journalMouvement = journalMouvementRepository.findById(journalId)
                                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                                                "Journal introuvable"));

                List<Commande> commandes = commandeRepository.findAllByJournalMouvementId(journalId);
                return versResponse(commandes);

        }

        private CommandeResponseAll versResponse(List<Commande> commandes) {
                List<CommandeResponse> responses = new ArrayList<>();
                for (Commande commandeSauvegardee : commandes) {
                        CommandeResponse response = new CommandeResponse(
                                        commandeSauvegardee.getId(),
                                        commandeSauvegardee.getJournalMouvement().getId(),
                                        commandeSauvegardee.getArticle().getId(),
                                        commandeSauvegardee.getArticle().getNomArticle(),
                                        commandeSauvegardee.getQuantiteDemandee());

                        responses.add(response);
                }

                return new CommandeResponseAll(responses);
        }

        @Transactional
        public List<MeilleurEmplacementResponse> proposerEmplacement(Long idCommande) {
                // Prendre la commande
                Commande commande = commandeRepository.findById(idCommande).orElseThrow(
                                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Commande introuvable"));

                Article articleRecherche = commande.getArticle();
                if (articleRecherche == null) {
                        throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                                        "Article de la commande" + commande.getId() + "introuvable");
                }

                ArticleConditionnement articleConditionnement = articleRecherche.getArticleConditionnements().get(0);
                List<StockProjection> stockProjections = stockRepository.findBestArticle(articleRecherche.getId());
                List<MeilleurEmplacementResponse> meilleursEmplacements = new ArrayList<>();

                Integer quantiteRestante = commande.getQuantiteDemandee();
                for (StockProjection stockProjection : stockProjections) {

                        Emplacement emplacementPropose = emplacementRepository
                                        .findById(stockProjection.getEmplacementId())
                                        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                                                        "l'emplacement proposé n'est pas trouvé"));
                        Integer quantiteStocke = stockProjection.getQuantiteStock();

                        Integer quantiteConditionnementStocke = quantiteStocke
                                        / articleConditionnement.getQuantitePieceStandard();
                        Long rackId = emplacementPropose.getRack().getId();
                        String nomRack = emplacementPropose.getRack().getNomRack();
                        Integer numeroEtage = emplacementPropose.getNumeroEtage();
                        if (quantiteRestante <= 0) {
                                break;
                        }

                        Integer quantiteAPrelever = Math.min(
                                        quantiteConditionnementStocke,
                                        quantiteRestante);

                        quantiteRestante -= quantiteAPrelever;
                        LocalDate dlc = stockProjection.getDlc();

                        MeilleurEmplacementResponse meilleurEmplacementResponse = new MeilleurEmplacementResponse(
                                        emplacementPropose.getId(), emplacementPropose.getNomEmplacement(), rackId,
                                        nomRack, numeroEtage, commande.getId(), quantiteStocke, quantiteAPrelever, dlc,
                                        stockProjection.getDlv(),
                                        emplacementPropose.getRack().getOrdre(),
                                        emplacementPropose.getOrdreDansEtage());

                        meilleursEmplacements.add(meilleurEmplacementResponse);
                }

                return meilleursEmplacements;

        }

        @Transactional
        public PrelevementResponse UpdateCommandeAndDetailJournal(AjoutCommandeRequest ajoutCommandeRequest) {

                Emplacement emplacement = emplacementRepository.findById(ajoutCommandeRequest.EmplacementId())
                                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                                                "Emplacement introuvable"));
                Article article = articleRepository.findById(ajoutCommandeRequest.ArticleId())
                                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                                                "Emplacement introuvable"));
                List<Article> articlesPresents = mouvementStockRepository
                                .findArticlesPresentsByEmplacementId(emplacement.getId());

                StatutPrelevement statutPrelevement = statuPrelevementRepository.findByNomStatut(STATUT_PRELEVE)
                                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                                                "Statut not found "));
                boolean articleEstLa = false;

                User user = userRepository.findByMatricule(ajoutCommandeRequest.matricule())
                                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                                                "User not found !"));

                Commande commande = commandeRepository.findById(ajoutCommandeRequest.CommandeId()).orElseThrow(
                                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "commande introuvable"));

                if (!commande.getArticle().getId().equals(article.getId())) {
                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "Cet article ne correspond pas à la commande");
                }

                if (!commande.getJournalMouvement().getId()
                                .equals(ajoutCommandeRequest.idJournal())) {
                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "Cette commande n'appartient pas à ce journal");
                }

                List<Prelevement> allPrelevement = prelevementRepository.findAllByCommandeId(commande.getId());

                // stock total scanne
                Integer stockTotalScanne = 0;
                for (Prelevement prelevement : allPrelevement) {
                        stockTotalScanne += prelevement.getQuantitePiecesPrelevees()
                                        / article.getArticleConditionnements().get(0).getQuantitePieceStandard();
                }

                long stockActuelScanMiampy = stockTotalScanne + ajoutCommandeRequest.quantiteConditionnement();
                if (stockActuelScanMiampy > commande.getQuantiteDemandee()) {
                        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Excès !!! ");
                }
                Prelevement prelevement = new Prelevement();

                for (Article articlePresent : articlesPresents) {
                        if (articlePresent.getId().equals(article.getId())) {
                                articleEstLa = true;
                        }

                }
                ArticleConditionnement articleConditionnement = article.getArticleConditionnements().get(0);
                Integer quantitePieceStandard = articleConditionnement.getQuantitePieceStandard();
                if (!articleEstLa) {
                        throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                                        "l'article selectionne n'est pas sur l'emplacement");
                }

                long quantitePresent = mouvementStockRepository
                                .calculerNombreConditionnementsPresents(emplacement.getId());

                if (quantitePresent < ajoutCommandeRequest.quantiteConditionnement()) {

                        throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                                        "stock insuffisant sur l'emplacement" + emplacement.getNomEmplacement());
                }

                Integer quantitePiecesPrelevees = Math.multiplyExact(
                                ajoutCommandeRequest.quantiteConditionnement(),
                                quantitePieceStandard);
                detailJournalRepository.ajouterOuIncrementer(
                                ajoutCommandeRequest.idJournal(),
                                article.getId(),
                                quantitePiecesPrelevees,
                                quantitePieceStandard,
                                null,
                                null);

                // Prelevement prelevement =

                // prelevementRepository.findById((long)id).orElseThrow(() -> new
                // ResponseStatusException(HttpStatus.NOT_FOUND,"Prelevement inséré
                // introuvable"));
                prelevement.setCommande(commande);
                prelevement.setEmplacement(emplacement);
                prelevement.setStatutPrelevement(statutPrelevement);
                prelevement.setUser(user);
                prelevement.setQuantitePiecesPrelevee(quantitePiecesPrelevees);
                prelevement.setDate(LocalDateTime.now());
                prelevement.setDlc(ajoutCommandeRequest.dlc());
                prelevement.setDlv(ajoutCommandeRequest.dlv());

                Prelevement reponse = prelevementRepository.save(prelevement);

                return new PrelevementResponse(reponse.getId(), ajoutCommandeRequest.CommandeId(), article.getId(),
                                article.getNomArticle(), emplacement.getId(), emplacement.getNomEmplacement(),
                                ajoutCommandeRequest.quantiteConditionnement(), quantitePiecesPrelevees,
                                statutPrelevement.getNomStatut(), LocalDateTime.now(), ajoutCommandeRequest.dlc(),
                                ajoutCommandeRequest.dlv());
                // detailJournalRepository.ajouterOuIncrementer(ajoutCommandeRequest.idJournal(),ajoutCommandeRequest.ArticleId(),ajoutCommandeRequest.quantiteConditionnement(),)
        }

        @Transactional
        public List<MeilleurEmplacementResponse> proposerMeilleurParcours(
                        Long journalId) {

                JournalMouvement journal = journalMouvementRepository.findById(journalId)
                                .orElseThrow(() -> new ResponseStatusException(
                                                HttpStatus.NOT_FOUND,
                                                "Journal introuvable"));

                // SORTIE est un type de mouvement, pas un statut.
                if (!"SORTIE".equals(
                                journal.getTypeMouvementJournal().getNomTypeMouvement())) {

                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "Le journal n'est pas de type sortie");
                }

                List<Commande> commandesJournal = journal.getCommandes();

                if (commandesJournal.isEmpty()) {
                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "La liste des commandes est vide");
                }

                // Une seule liste, et non une liste de listes.
                List<MeilleurEmplacementResponse> meilleurParcours = new ArrayList<>();

                for (Commande commande : commandesJournal) {
                        List<MeilleurEmplacementResponse> propositions = proposerEmplacement(commande.getId());

                        // Ajoute chaque proposition individuellement.
                        meilleurParcours.addAll(propositions);
                }

                meilleurParcours.sort(
                                Comparator.comparing(
                                                MeilleurEmplacementResponse::ordre,
                                                Comparator.nullsLast(Integer::compareTo))
                                                .thenComparing(
                                                                MeilleurEmplacementResponse::numeroEtage,
                                                                Comparator.nullsLast(Integer::compareTo))
                                                .thenComparing(
                                                                MeilleurEmplacementResponse::ordreEmplacement,
                                                                Comparator.nullsLast(Integer::compareTo)));

                return meilleurParcours;
        }

        @Transactional
        public List<LignePickingResponse> genererMeilleurParcours(
                        Long journalId,
                        Long userId,
                        Long rackDepartId) {

                JournalMouvement journal = journalMouvementRepository.findById(journalId)
                                .orElseThrow(() -> new ResponseStatusException(
                                                HttpStatus.NOT_FOUND,
                                                "Journal introuvable"));

                if (!"SORTIE".equals(
                                journal.getTypeMouvementJournal().getNomTypeMouvement())) {
                        throw new ResponseStatusException(
                                        HttpStatus.BAD_REQUEST,
                                        "Le journal doit etre de type SORTIE");
                }

                User user = userRepository.findById(userId)
                                .orElseThrow(() -> new ResponseStatusException(
                                                HttpStatus.NOT_FOUND,
                                                "Utilisateur introuvable"));

                Rack rackDepart = rackRepository.findById(rackDepartId)
                                .orElseThrow(() -> new ResponseStatusException(
                                                HttpStatus.NOT_FOUND,
                                                "Rack de depart introuvable"));

                if (pickingRepository.existsByJournalMouvementIdAndStatutIn(
                                journalId,
                                List.of(StatutPicking.GENERE, StatutPicking.EN_COURS))) {
                        throw new ResponseStatusException(
                                        HttpStatus.CONFLICT,
                                        "Un picking est deja en cours pour ce journal");
                }

                List<MeilleurEmplacementResponse> propositions = proposerMeilleurParcours(journalId);

                if (propositions.isEmpty()) {
                        throw new ResponseStatusException(
                                        HttpStatus.CONFLICT,
                                        "Aucun stock disponible pour les commandes de ce journal");
                }

                // On refuse de creer un picking partiel.
                for (Commande commande : journal.getCommandes()) {
                        int quantiteProposee = 0;

                        for (MeilleurEmplacementResponse proposition : propositions) {
                                if (proposition.commandeId().equals(commande.getId())) {
                                        quantiteProposee += proposition.quantiteAPrelever();
                                }
                        }

                        if (quantiteProposee < commande.getQuantiteDemandee()) {
                                throw new ResponseStatusException(
                                                HttpStatus.CONFLICT,
                                                "Stock insuffisant pour l'article : "
                                                                + commande.getArticle().getNomArticle());
                        }
                }

                Picking picking = new Picking(journal, user, rackDepart);
                Picking pickingSauvegarde = pickingRepository.save(picking);

                List<LignePickingResponse> lignesCreees = new ArrayList<>();
                int ordrePassage = 1;

                for (MeilleurEmplacementResponse proposition : propositions) {
                        Commande commande = commandeRepository.findById(
                                        proposition.commandeId()).orElseThrow(
                                                        () -> new ResponseStatusException(
                                                                        HttpStatus.NOT_FOUND,
                                                                        "Commande introuvable"));

                        ArticleConditionnement conditionnement = articleConditionnementRepository
                                        .findFirstByArticleIdOrderByIdAsc(
                                                        commande.getArticle().getId())
                                        .orElseThrow(() -> new ResponseStatusException(
                                                        HttpStatus.NOT_FOUND,
                                                        "Conditionnement introuvable pour l'article"));

                        LignePickingCreateRequest request = new LignePickingCreateRequest(
                                        pickingSauvegarde.getId(),
                                        proposition.commandeId(),
                                        proposition.emplacementId(),
                                        proposition.dlc(),
                                        proposition.dlv(),
                                        conditionnement.getId(),
                                        ordrePassage,
                                        proposition.quantiteAPrelever());

                        LignePickingResponse ligne = lignePickingService.creerLigne(request);

                        lignesCreees.add(ligne);
                        ordrePassage++;
                }

                return lignesCreees;
        }
}

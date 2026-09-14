package com.example.demo.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.demo.dto.*;
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

        public CommandeService(JournalMouvementRepository journalMouvementRepository,
                        ArticleRepository articleRepository,
                        EmplacementRepository emplacementRepository, MouvementStockRepository mouvementStockRepository,
                        CommandeRepository commandeRepository, DetailJournalRepository detailJournalRepository,
                        PrelevementRepository prelevementRepository,
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
                                        nomRack, numeroEtage, commande.getId(), quantiteStocke, quantiteAPrelever, dlc);

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
        
        
}
